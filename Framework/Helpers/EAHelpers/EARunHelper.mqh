//+------------------------------------------------------------------+
//|                                                     EARunHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\Ticket.mqh>

class EARunHelper
{
public:
    template <typename TEA>
    static bool BelowSpread(TEA &ea);
    template <typename TEA>
    static bool PastMinROCOpenTime(TEA &ea);
    template <typename TEA>
    static bool WithinTradingSession(TEA &ea);

    template <typename TEA>
    static void Run(TEA &ea);

    template <typename TEA>
    static void ShowOpenTicketProfit(TEA &ea);

private:
    template <typename TEA>
    static void ManagePreviousSetupTickets(TEA &ea);
    template <typename TEA>
    static void ManageCurrentSetupTicket(TEA &ea);
    template <typename TEA>
    static bool CheckCurrentSetupTicket(TEA &ea, Ticket &ticket); // returns true if the ticket has been closed
    template <typename TEA>
    static bool CheckPreviousSetupTicket(TEA &ea, Ticket &ticket); // return true if the ticket has been closed
    template <typename TEA>
    static void CheckUpdateHowFarPriceRanFromOpen(TEA &ea, Ticket &ticket);
};

template <typename TEA>
static bool EARunHelper::BelowSpread(TEA &ea)
{
    return (SymbolInfoInteger(ea.EntrySymbol(), SYMBOL_SPREAD) / 10) <= ea.mMaxSpreadPips;
}

template <typename TEA>
static bool EARunHelper::PastMinROCOpenTime(TEA &ea)
{
    return ea.mMRFTS.OpenPrice() > 0.0 || ea.mHasSetup;
}

template <typename TEA>
static bool EARunHelper::WithinTradingSession(TEA &ea)
{
    for (int i = 0; i < ea.mTradingSessions.Size(); i++)
    {
        if (ea.mTradingSessions[i].CurrentlyWithinSession())
        {
            return true;
        }
    }

    return false;
}

template <typename TEA>
static void EARunHelper::Run(TEA &ea)
{
    ea.PreRun();

    // These needs to be done first since the proceeding logic can depend on the ticket being activated or closed
    ea.PreManageTickets();
    ManageCurrentSetupTicket(ea);
    ManagePreviousSetupTickets(ea);

    ea.CheckInvalidateSetup();

    if (!ea.mWasReset && ea.ShouldReset())
    {
        ea.Reset();
        ea.mWasReset = true;
    }

    if (!ea.AllowedToTrade())
    {
        return;
    }

    if (ea.mStopTrading)
    {
        return;
    }

    ea.mWasReset = false;

    if (!ea.mHasSetup)
    {
        ea.CheckSetSetup();
    }

    if (ea.mHasSetup)
    {
        if (ea.mCurrentSetupTickets.IsEmpty())
        {
            if (ea.Confirmation())
            {
                ea.PlaceOrders();
            }
        }
        else
        {
            ea.mLastState = EAStates::CHECKING_IF_CONFIRMATION_IS_STILL_VALID;
            for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
            {
                bool wasActivated;
                int wasActivatedError = ea.mCurrentSetupTickets[i].WasActivated(wasActivated);
                if (Errors::IsTerminalError(wasActivatedError))
                {
                    ea.InvalidateSetup(false, wasActivatedError);
                    return;
                }

                if (!wasActivated && !ea.Confirmation())
                {
                    ea.mCurrentSetupTickets[i].Close();
                    ea.mCurrentSetupTickets.RemoveWhere<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, ea.mCurrentSetupTickets[i].Number());
                }
            }
        }
    }
}

template <typename TEA>
static void EARunHelper::ShowOpenTicketProfit(TEA &ea)
{
    string profitObjectName = "ProfitLabel" + (ea.SetupType() == SignalType::Bearish ? "Bearish" : "Bullish");
    if (ea.mCurrentSetupTickets.Size() > 0)
    {
        double profit = 0.0;
        for (int i = 0; i < ea.mCurrentSetupTickets.Size(); i++)
        {
            profit += ea.mCurrentSetupTickets[i].Profit();
        }

        color clr = profit > 0 ? clrLime : clrMagenta;
        string text = StringFormat("$%.2f", profit);

        if (ObjectFind(ChartID(), profitObjectName) < 0)
        {
            if (!ObjectCreate(ChartID(), profitObjectName, OBJ_LABEL, 0, 0, 0))
            {
                Print("Failed to create obj. ", GetLastError());
                return;
            }

            ObjectSet(profitObjectName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSet(profitObjectName, OBJPROP_XDISTANCE, 20);
            ObjectSet(profitObjectName, OBJPROP_YDISTANCE, 20);
        }

        ObjectSetText(profitObjectName, text, 30, "Times New Roman", clr);
    }
    else
    {
        if (ObjectFind(ChartID(), profitObjectName) >= 0)
        {
            ObjectDelete(ChartID(), profitObjectName);
        }
    }
}

template <typename TEA>
static void EARunHelper::ManageCurrentSetupTicket(TEA &ea)
{
    for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
    {
        // do any custom checking first since tickets will be removed in CheckCurrentSetupTicket if they are closed
        ea.CheckCurrentSetupTicket(ea.mCurrentSetupTickets[i]);

        // default checking that every ticket needs to go through
        CheckUpdateHowFarPriceRanFromOpen(ea, ea.mCurrentSetupTickets[i]);
        CheckCurrentSetupTicket(ea, ea.mCurrentSetupTickets[i]);
    }

    // do a different loop in case the tickets were closed above
    for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
    {
        if (ea.MoveToPreviousSetupTickets(ea.mCurrentSetupTickets[i]))
        {
            Ticket *ticket = new Ticket(ea.mCurrentSetupTickets[i]);

            ea.mPreviousSetupTickets.Add(ticket);
            ea.mCurrentSetupTickets.RemoveWhere<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, ticket.Number());

            // no longer a current ticket, can continue
            continue;
        }

        bool isActive;
        int isActiveError = ea.mCurrentSetupTickets[i].IsActive(isActive);
        if (Errors::IsTerminalError(isActiveError))
        {
            ea.InvalidateSetup(false, isActiveError);
            return;
        }

        if (isActive)
        {
            ea.ManageCurrentActiveSetupTicket(ea.mCurrentSetupTickets[i]);
        }
        else
        {
            ea.ManageCurrentPendingSetupTicket(ea.mCurrentSetupTickets[i]);
        }
    }
}

template <typename TEA>
static void EARunHelper::ManagePreviousSetupTickets(TEA &ea)
{
    // do 2 different loops since tickets can be clsoed and deleted in CheckPreviousSetupTickets.
    // can't manage tickets that were just closed and deleted
    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
    {
        // do any custom checking first since tickets will be removed in CheckPreviousSetupTicket if they are closed
        ea.CheckPreviousSetupTicket(ea.mPreviousSetupTickets[i]);

        // default checking that every ticket needs to go through
        CheckUpdateHowFarPriceRanFromOpen(ea, ea.mPreviousSetupTickets[i]);
        CheckPreviousSetupTicket(ea, ea.mPreviousSetupTickets[i]);
    }

    // do a different loop just in case the tickets were closed above
    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
    {
        ea.ManagePreviousSetupTicket(ea.mPreviousSetupTickets[i]);
    }
}
template <typename TEA>
bool EARunHelper::CheckCurrentSetupTicket(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_TICKET;

    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return true;
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool wasActivatedSinceLastCheck = false;
    int activatedError = ticket.WasActivatedSinceLastCheck(__FUNCTION__, wasActivatedSinceLastCheck);
    if (Errors::IsTerminalError(activatedError))
    {
        ea.InvalidateSetup(false, activatedError);
        return false;
    }

    if (wasActivatedSinceLastCheck)
    {
        ticket.OriginalStopLoss(ticket.CurrentStopLoss());
        ea.RecordTicketOpenData(ticket);
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_CLOSED;

    bool closed = false;
    int closeError = ticket.WasClosedSinceLastCheck(__FUNCTION__, closed);
    if (Errors::IsTerminalError(closeError))
    {
        ea.InvalidateSetup(false, closeError);
        return false;
    }

    if (closed)
    {
        bool wasActivated = false;
        int wasAtivatedError = ticket.WasActivated(wasActivated);
        if (Errors::IsTerminalError(wasAtivatedError))
        {
            ea.InvalidateSetup(false, wasAtivatedError);
            // don't return here so we can still remove the ticket. WasActivated should be false
        }

        // only record tickets that were actually opened and not pennding orders that were deleted
        if (wasActivated)
        {
            if (AccountInfoDouble(ACCOUNT_BALANCE) > ea.mLargestAccountBalance)
            {
                ea.mLargestAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            }

            ea.RecordTicketCloseData(ticket);
        }

        ea.mCurrentSetupTickets.RemoveWhere<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, ticket.Number());
        return true;
    }

    return false;
}

template <typename TEA>
static bool EARunHelper::CheckPreviousSetupTicket(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_PREVIOUS_SETUP_TICKET;
    bool closed = false;
    int closeError = ticket.WasClosedSinceLastCheck(__FUNCTION__, closed);
    if (Errors::IsTerminalError(closeError))
    {
        ea.RecordError(__FUNCTION__, closeError, "");
        return false;
    }

    if (closed)
    {
        if (AccountInfoDouble(ACCOUNT_BALANCE) > ea.mLargestAccountBalance)
        {
            ea.mLargestAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        }

        ea.RecordTicketCloseData(ticket);
        ea.mPreviousSetupTickets.RemoveWhere<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, ticket.Number());

        return true;
    }

    return false;
}

template <typename TEA>
static void EARunHelper::CheckUpdateHowFarPriceRanFromOpen(TEA &ea, Ticket &ticket)
{
    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    double distanceRan;
    TicketType ticketType = ticket.Type();
    if (ticketType == TicketType::Buy)
    {
        distanceRan = ea.CurrentTick().Bid() - ticket.OpenPrice();
    }
    else if (ticketType == TicketType::Sell)
    {
        distanceRan = ticket.OpenPrice() - ea.CurrentTick().Ask();
    }

    if (distanceRan > ticket.DistanceRanFromOpen())
    {
        ticket.DistanceRanFromOpen(distanceRan);
    }
}