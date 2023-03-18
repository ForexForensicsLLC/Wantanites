//+------------------------------------------------------------------+
//|                                                       Ticket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>

#include <Wantanites\Framework\Constants\ExecutionErrors.mqh>
#include <Wantanites\Framework\Constants\TerminalErrors.mqh>

#include <Wantanites\Framework\Objects\DataObjects\Partial.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

class Ticket
{
private:
    typedef bool (*TTicketNumberLocator)(Ticket &, int);
    int mNumber;

    bool mLastCloseCheck;
    bool mLastActiveCheck;

    bool mWasActivated;
    bool mIsClosed;

    double mOriginalOpenPrice;
    double mOpenPrice;
    double mOriginalStopLoss;
    datetime mOpenTime;
    double mLots;
    double mRRAcquired;
    double mDistanceRanFromOpen;
    bool mStopLossIsMovedToBreakEven;

    int SelectTicket(string action, bool fallbackSearchOpen);

public:
    Ticket();
    Ticket(int ticket);
    Ticket(Ticket &ticket);
    ~Ticket();

    string DisplayName() { return "Ticket"; }

    ObjectList<Partial> *mPartials;

    // Dictionary of <function name chcking if a ticket was activated or closed, previous result>
    Dictionary<string, bool> *mActivatedSinceLastCheckCheckers;
    Dictionary<string, bool> *mClosedSinceLastCheckCheckers;

    int Number() { return mNumber; }

    int Type();

    double OriginalOpenPrice();
    void OriginalOpenPrice(double originalOpenPrice) { mOriginalOpenPrice = originalOpenPrice; }

    double OpenPrice();
    void OpenPrice(double openPrice) { mOpenPrice = openPrice; }

    datetime OpenTime();
    void OpenTime(datetime openTime) { mOpenTime = openTime; }

    double OriginalStopLoss();
    void OriginalStopLoss(double originalStopLoss) { mOriginalStopLoss = originalStopLoss; }

    double Lots();
    void Lots(double lots) { mLots = lots; }

    double TakeProfit();
    double Profit();

    double RRAcquired() { return mRRAcquired; }
    void RRAcquired(double rrAcquired) { mRRAcquired = rrAcquired; }

    double DistanceRanFromOpen() { return mDistanceRanFromOpen; }
    void DistanceRanFromOpen(double distanceRanFromOpen) { mDistanceRanFromOpen = distanceRanFromOpen; }

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);
    void SetStopLossIsMovedToBreakEven(bool stopLossIsMovedToBreakEven) { mStopLossIsMovedToBreakEven = stopLossIsMovedToBreakEven; }

    void SetNewTicket(int ticket);
    void UpdateTicketNumber(int newTicketNumber);

    int SelectIfOpen(string action);
    int SelectIfClosed(string action);

    int IsActive(bool &active);
    int WasActivated(bool &active);
    int WasActivatedSinceLastCheck(string checker, bool &active);

    int IsClosed(bool &closed);
    int WasClosedSinceLastCheck(string checker, bool &closed);

    int Close();
    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);

    static bool HasTicketNumber(Ticket &ticket, int ticketNumber);
};

Ticket::Ticket()
{
    mPartials = new ObjectList<Partial>();
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>();
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>();

    SetNewTicket(EMPTY);
}

Ticket::Ticket(int ticket)
{
    mPartials = new ObjectList<Partial>();
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>();
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>();

    SetNewTicket(ticket);
}

Ticket::Ticket(Ticket &ticket)
{
    mNumber = ticket.Number();
    mRRAcquired = ticket.mRRAcquired;

    mPartials = new ObjectList<Partial>(ticket.mPartials);
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>(ticket.mActivatedSinceLastCheckCheckers);
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>(ticket.mClosedSinceLastCheckCheckers);

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
    delete mActivatedSinceLastCheckCheckers;
    delete mClosedSinceLastCheckCheckers;
}

void Ticket::SetNewTicket(int ticket)
{
    mNumber = ticket;

    mLastCloseCheck = false;
    mLastActiveCheck = false;

    mWasActivated = false;
    mIsClosed = false;

    mRRAcquired = ConstantValues::EmptyDouble;
    mStopLossIsMovedToBreakEven = false;
    mDistanceRanFromOpen = ConstantValues::EmptyDouble;

    mOpenPrice = ConstantValues::EmptyDouble;
    mOpenTime = EMPTY;
    mOriginalStopLoss = ConstantValues::EmptyDouble;
    mLots = ConstantValues::EmptyDouble;

    mPartials.Clear();
    mActivatedSinceLastCheckCheckers.Clear();
    mClosedSinceLastCheckCheckers.Clear();
}

int Ticket::Type()
{
    int selectError = SelectIfOpen("Retrieving Type");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Type",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return -1;
    }

    return OrderType();
}

// Note: This won't be accurate if I ever alter the open price on a ticket before it gets opened
double Ticket::OriginalOpenPrice()
{
    if (mOriginalOpenPrice != ConstantValues::EmptyDouble)
    {
        return mOriginalOpenPrice;
    }

    int selectError = SelectIfOpen("Retrieving Open Price");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    if (OrderType() <= 2)
    {
        return mOriginalOpenPrice;
    }

    mOriginalOpenPrice = OrderOpenPrice();
    return mOriginalOpenPrice;
}

double Ticket::OpenPrice()
{
    if (mOpenPrice != ConstantValues::EmptyDouble)
    {
        return mOpenPrice;
    }

    int selectError = SelectIfOpen("Retrieving Open Price");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    mOpenPrice = OrderOpenPrice();
    return mOpenPrice;
}

datetime Ticket::OpenTime()
{
    if (mOpenTime != EMPTY)
    {
        return mOpenTime;
    }

    int selectError = SelectIfOpen("Retrieving Open Time");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return EMPTY;
    }

    mOpenTime = OrderOpenTime();
    return mOpenTime;
}

// Note: This won't be accurate if I ever alter the open price on a ticket before it gets opened
double Ticket::OriginalStopLoss()
{
    if (mOriginalStopLoss != ConstantValues::EmptyDouble)
    {
        return mOriginalStopLoss;
    }

    int selectError = SelectIfOpen("Retrieving Open Price");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    if (OrderType() <= 2)
    {
        return mOriginalStopLoss;
    }

    mOriginalStopLoss = OrderStopLoss();
    return mOriginalStopLoss;
}

double Ticket::Lots()
{
    if (mLots != ConstantValues::EmptyDouble)
    {
        return mLots;
    }

    int selectError = SelectIfOpen("Retrieving Lots");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Lots",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    mLots = OrderLots();
    return mLots;
}

double Ticket::Profit()
{
    int selectError = SelectIfOpen("Retrieving Profit");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Profit",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    return OrderProfit();
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

int Ticket::WasActivatedSinceLastCheck(string checker, bool &wasActivatedSinceLastCheck)
{
    wasActivatedSinceLastCheck = false;

    if (!mActivatedSinceLastCheckCheckers.HasKey(checker))
    {
        mActivatedSinceLastCheckCheckers.Add(checker, false);
    }
    else
    {
        bool lastCheck = false;
        if (!mActivatedSinceLastCheckCheckers.GetValueByKey(checker, lastCheck))
        {
            return ExecutionErrors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return ERR_NO_ERROR;
        }
    }

    bool wasActivated = false;
    int wasActivatedError = WasActivated(wasActivated);
    if (wasActivatedError != ERR_NO_ERROR)
    {
        return wasActivatedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mActivatedSinceLastCheckCheckers.UpdateValueForKey(checker, wasActivated);
    wasActivatedSinceLastCheck = wasActivated;

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

    mIsClosed = true;
    closed = mIsClosed;

    return ERR_NO_ERROR;
}

int Ticket::WasClosedSinceLastCheck(string checker, bool &wasClosedSinceLastCheck)
{
    wasClosedSinceLastCheck = false;

    if (!mClosedSinceLastCheckCheckers.HasKey(checker))
    {
        mClosedSinceLastCheckCheckers.Add(checker, false);
    }
    else
    {
        bool lastCheck = false;
        if (!mClosedSinceLastCheckCheckers.GetValueByKey(checker, lastCheck))
        {
            return ExecutionErrors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return ERR_NO_ERROR;
        }
    }

    bool isClosed = false;
    int closedError = IsClosed(isClosed);
    if (closedError != ERR_NO_ERROR)
    {
        return closedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mClosedSinceLastCheckCheckers.UpdateValueForKey(checker, isClosed);
    wasClosedSinceLastCheck = isClosed;

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
        double stopLoss = NormalizeDouble(OrderStopLoss(), Digits);
        double openPrice = NormalizeDouble(OrderOpenPrice(), Digits);

        if (OrderType() == OP_BUY)
        {
            mStopLossIsMovedToBreakEven = stopLoss >= openPrice;
        }
        else if (OrderType() == OP_SELL)
        {
            mStopLossIsMovedToBreakEven = stopLoss <= openPrice;
        }
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

static bool Ticket::HasTicketNumber(Ticket &ticket, int number)
{
    return ticket.Number() == number;
}