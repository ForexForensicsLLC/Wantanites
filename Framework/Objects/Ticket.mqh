//+------------------------------------------------------------------+
//|                                                       Ticket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\ExecutionErrors.mqh>
#include <SummitCapital\Framework\Constants\TerminalErrors.mqh>

#include <SummitCapital\Framework\Objects\List.mqh>
#include <SummitCapital\Framework\Objects\PartialList.mqh>

class Ticket
{
private:
    int mNumber;

    bool mLastCloseCheck;
    bool mLastActiveCheck;

    bool mWasActivated;
    bool mIsClosed;

    bool mStopLossIsMovedToBreakEven;

    double mOpenPrice;
    datetime mOpenTime;
    double mLots;

    int SelectTicket(string action, bool fallbackSearchOpen);

public:
    Ticket();
    Ticket(int ticket);
    Ticket(Ticket &ticket);
    ~Ticket();

    ObjectList<Partial> *mPartials;

    double mRRAcquired;
    double mOriginalStopLoss;
    double mDistanceRanFromOpen;

    int Number() { return mNumber; }

    double OpenPrice();
    void OpenPrice(double openPrice) { mOpenPrice = openPrice; }

    datetime OpenTime();
    void OpenTime(datetime openTime) { mOpenTime = openTime; }

    double Lots();
    void Lots(double lots) { mLots = lots; }

    void SetNewTicket(int ticket);
    void UpdateTicketNumber(int newTicketNumber);

    int SelectIfOpen(string action);
    int SelectIfClosed(string action);

    int IsActive(bool &active);
    int WasActivated(bool &active);
    int WasActivatedSinceLastCheck(bool &active);

    int IsClosed(bool &closed);
    int WasClosedSinceLastCheck(bool &closed);

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);

    int Close();
    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);
};

Ticket::Ticket()
{
    mPartials = new ObjectList<Partial>();
    SetNewTicket(EMPTY);
}

Ticket::Ticket(int ticket)
{
    mPartials = new ObjectList<Partial>();
    SetNewTicket(ticket);
}

Ticket::Ticket(Ticket &ticket)
{
    mNumber = ticket.Number();
    mRRAcquired = ticket.mRRAcquired;
    mPartials = new ObjectList<Partial>(ticket.mPartials);

    mDistanceRanFromOpen = ticket.mDistanceRanFromOpen;
    mOpenPrice = ticket.OpenPrice();
    mOpenTime = ticket.OpenTime();
    mOriginalStopLoss = ticket.mOriginalStopLoss;
    mLots = ticket.Lots();

    // update this tickets status' by calling the old tickets methods
    // do this just in case something changed since the last check
    ticket.WasActivated(mWasActivated);
    ticket.IsClosed(mIsClosed);
    ticket.StopLossIsMovedToBreakEven(mStopLossIsMovedToBreakEven);
}

Ticket::~Ticket()
{
    delete mPartials;
}

void Ticket::SetNewTicket(int ticket)
{
    mNumber = ticket;

    mLastCloseCheck = false;
    mLastActiveCheck = false;

    mWasActivated = false;
    mIsClosed = false;

    mRRAcquired = 0;
    mStopLossIsMovedToBreakEven = false;
    mDistanceRanFromOpen = 0.0;

    mOpenPrice = 0.0;
    mOpenTime = 0;
    mOriginalStopLoss = 0.0;
    mLots = 0.0;

    mPartials.Clear();
}

double Ticket::OpenPrice()
{
    if (mOpenPrice != 0.0)
    {
        return mOpenPrice;
    }

    int selectError = SelectIfOpen("Retrieving Open Price");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0.0;
    }

    mOpenPrice = OrderOpenPrice();
    return mOpenPrice;
}

datetime Ticket::OpenTime()
{
    if (mOpenTime != 0)
    {
        return mOpenTime;
    }

    int selectError = SelectIfOpen("Retrieving Open Time");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mOpenTime = OrderOpenTime();
    return mOpenTime;
}

double Ticket::Lots()
{
    if (mLots != 0.0)
    {
        return mLots;
    }

    int selectError = SelectIfOpen("Retrieving Lots");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Lots",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mLots = OrderLots();
    return mLots;
}

void Ticket::UpdateTicketNumber(int newTicketNumber)
{
    mNumber = newTicketNumber;
    mWasActivated = false;
    mIsClosed = false;
    mStopLossIsMovedToBreakEven = false;
}

int Ticket::SelectTicket(string action, bool fallbackSearchOpen)
{
    // for some reason selecting by ticket will randomly fail. If it does, we will loop thorugh all tickets
    // manually and try to find it
    if (!OrderSelect(mNumber, SELECT_BY_TICKET))
    {
        bool found = false;

        int count = fallbackSearchOpen ? OrdersTotal() : OrdersHistoryTotal();
        int pool = fallbackSearchOpen ? MODE_TRADES : MODE_HISTORY;

        for (int i = 0; i < count; i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS, pool))
            {
                int error = GetLastError();
                SendMail("Failed To Select Order By Ticket When " + action,
                         "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                             "Current Index: " + IntegerToString(i) + "\n" +
                             "Current Ticket: " + IntegerToString(mNumber) + "\n" +
                             IntegerToString(error));

                return error;
            }

            if (OrderTicket() == mNumber)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            return TerminalErrors::ORDER_NOT_FOUND;
        }
    }

    return ERR_NO_ERROR;
}

int Ticket::SelectIfOpen(string action)
{
    int selectOrderError = SelectTicket(action, true);
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    if (OrderCloseTime() != 0)
    {
        return ExecutionErrors::ORDER_IS_CLOSED;
    }

    return ERR_NO_ERROR;
}

int Ticket::SelectIfClosed(string action)
{
    int selectOrderError = SelectTicket(action, false);
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    if (OrderCloseTime() == 0)
    {
        return ExecutionErrors::ORDER_IS_OPEN;
    }

    return ERR_NO_ERROR;
}

int Ticket::IsActive(bool &isActive)
{
    isActive = false;

    int selectTicketError = SelectIfOpen("Checking if Active");
    if (selectTicketError != ERR_NO_ERROR)
    {
        return selectTicketError;
    }

    if (OrderType() >= 2)
    {
        return ERR_NO_ERROR;
    }

    isActive = true;
    return ERR_NO_ERROR;
}

int Ticket::WasActivated(bool &wasActivated)
{
    if (mWasActivated)
    {
        wasActivated = mWasActivated;
        return ERR_NO_ERROR;
    }

    int selectFromOpenOrdersError = SelectTicket("Checking if order is activated fallback open", true);
    if (selectFromOpenOrdersError != ERR_NO_ERROR)
    {
        // if we failed finding it we could have opened and closed the ticket between the last check.
        // If so we should check the closed tickets to see if our ticket is there
        int selectFromClosedOrdersError = SelectTicket("Checking if order is activated fallback closed", false);
        if (selectFromClosedOrdersError != ERR_NO_ERROR)
        {
            wasActivated = false;
            return selectFromClosedOrdersError;
        }
    }

    mWasActivated = OrderType() < 2;
    wasActivated = mWasActivated;

    return ERR_NO_ERROR;
}

int Ticket::WasActivatedSinceLastCheck(bool &wasActivatedSinceLastCheck)
{
    if (mWasActivated)
    {
        wasActivatedSinceLastCheck = !mLastActiveCheck;
        mLastActiveCheck = true;

        return ERR_NO_ERROR;
    }

    bool wasActivated = false;
    int wasActivatedError = WasActivated(wasActivated);
    if (wasActivatedError != ERR_NO_ERROR)
    {
        wasActivatedSinceLastCheck = false;
        return wasActivatedError;
    }

    wasActivatedSinceLastCheck = wasActivated;
    mLastActiveCheck = wasActivated;

    return ERR_NO_ERROR;
}

int Ticket::IsClosed(bool &closed)
{
    if (mIsClosed)
    {
        closed = true;
        return ERR_NO_ERROR;
    }

    int selectTicketError = SelectIfClosed("Checking if Closed");
    if (selectTicketError != ERR_NO_ERROR)
    {
        closed = false;
        return selectTicketError;
    }

    // ticket was never activated so it can't be considered closed
    if (OrderType() >= 2)
    {
        closed = false;
        return ERR_NO_ERROR;
    }

    mIsClosed = true;
    closed = mIsClosed;

    return ERR_NO_ERROR;
}

int Ticket::WasClosedSinceLastCheck(bool &wasClosedSinceLastCheck)
{
    if (mIsClosed)
    {
        wasClosedSinceLastCheck = !mLastCloseCheck;
        mLastCloseCheck = true;

        return ERR_NO_ERROR;
    }

    bool isClosed = false;
    int closedError = IsClosed(isClosed);
    if (closedError != ERR_NO_ERROR)
    {
        wasClosedSinceLastCheck = false;
        return closedError;
    }

    wasClosedSinceLastCheck = isClosed;
    mLastCloseCheck = isClosed;

    return ERR_NO_ERROR;
}

int Ticket::Close()
{
    int selectOrderError = SelectIfOpen("Closing");
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    // Pending Order
    if (OrderType() > 1)
    {
        if (!OrderDelete(mNumber, clrNONE))
        {
            return GetLastError();
        }
    }
    // Active Order
    else
    {
        double closeAt = OrderType() == OP_BUY ? Bid : Ask;
        if (!OrderClose(mNumber, OrderLots(), closeAt, 0, clrNONE))
        {
            return GetLastError();
        }
    }

    return ERR_NO_ERROR;
}

int Ticket::StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven)
{
    if (!mStopLossIsMovedToBreakEven)
    {
        int error = SelectIfOpen("Checking If Break Even");
        if (error != ERR_NO_ERROR)
        {
            return error;
        }

        // Need to normalize or else this will always return false on pairs that have more digits like currencies
        mStopLossIsMovedToBreakEven = (NormalizeDouble(OrderOpenPrice(), Digits) == NormalizeDouble(OrderStopLoss(), Digits));
    }

    stopLossIsMovedBreakEven = mStopLossIsMovedToBreakEven;
    return ERR_NO_ERROR;
}

void Ticket::SetPartials(List<double> &partialRRs, List<double> &partialPercents)
{
    for (int i = 0; i < partialRRs.Size(); i++)
    {
        Partial *partial = new Partial(partialRRs[i], partialPercents[i]);
        mPartials.Add(partial);
    }
}