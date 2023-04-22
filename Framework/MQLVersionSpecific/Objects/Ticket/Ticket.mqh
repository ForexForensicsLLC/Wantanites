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

#include <Wantanites\Framework\Constants\Errors.mqh>

#include <Wantanites\Framework\Objects\DataObjects\Partial.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\MQL4Ticket.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\MQL5Ticket.mqh>
#endif

class Ticket : public VersionSpecificTicket
{
private:
    bool mLastCloseCheck;
    bool mLastActiveCheck;

    bool mWasActivated;
    bool mIsClosed;

    double mExpectedOpenPrice;
    double mOriginalStopLoss;

    double mRRAcquired;
    double mDistanceRanFromOpen;
    bool mStopLossIsMovedToBreakEven;

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

    double ExpectedOpenPrice() { return mExpectedOpenPrice; }
    void ExpectedOpenPrice(double expectedOpenPrice) { mExpectedOpenPrice = expectedOpenPrice; }

    double OriginalStopLoss() { return mOriginalStopLoss; }
    void OriginalStopLoss(double originalStopLoss) { mOriginalStopLoss = originalStopLoss; }

    double RRAcquired() { return mRRAcquired; }
    void RRAcquired(double rrAcquired) { mRRAcquired = rrAcquired; }

    double DistanceRanFromOpen() { return mDistanceRanFromOpen; }
    void DistanceRanFromOpen(double distanceRanFromOpen) { mDistanceRanFromOpen = distanceRanFromOpen; }

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);
    void SetStopLossIsMovedToBreakEven(bool stopLossIsMovedToBreakEven) { mStopLossIsMovedToBreakEven = stopLossIsMovedToBreakEven; }

    void SetNewTicket(int ticket);
    void UpdateTicketNumber(int newTicketNumber);

    int IsActive(bool &isActive);
    int WasActivated(bool &active);
    int WasActivatedSinceLastCheck(string checker, bool &active);

    int IsClosed(bool &closed);
    int WasClosedSinceLastCheck(string checker, bool &closed);

    bool WasManuallyClosed() { return mWasManuallyClosed; }
    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);

    static bool EqualsTicketNumber(Ticket &ticket, int ticketNumber);
};

typedef bool (*TTicketNumberLocator)(Ticket &, int);

Ticket::Ticket()
{
    mPartials = new ObjectList<Partial>();
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>();
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>();

    SetNewTicket(ConstantValues::EmptyInt);
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
    mLotSize = ticket.LotSize();
    mClosePrice = ticket.ClosePrice();
    mCloseTime = ticket.CloseTime();

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

    mType = TicketType::Empty;
    mOpenPrice = ConstantValues::EmptyDouble;
    mOpenTime = 0;
    mOriginalStopLoss = ConstantValues::EmptyDouble;
    mLotSize = ConstantValues::EmptyDouble;
    mClosePrice = ConstantValues::EmptyDouble;
    mCloseTime = 0;
    mCommission = ConstantValues::EmptyDouble;

    mPartials.Clear();
    mActivatedSinceLastCheckCheckers.Clear();
    mClosedSinceLastCheckCheckers.Clear();
}

void Ticket::UpdateTicketNumber(int newTicketNumber)
{
    mNumber = newTicketNumber;
    mWasActivated = false;
    mIsClosed = false;
    mStopLossIsMovedToBreakEven = false;
}

int Ticket::IsActive(bool &isActive)
{
    isActive = false;

    int selectTicketError = SelectIfOpen("Checking if Active");
    if (selectTicketError != Errors::NO_ERROR)
    {
        return selectTicketError;
    }

    TicketType type = Type();
    isActive = type == TicketType::Buy || type == TicketType::Sell;
    return Errors::NO_ERROR;
}

int Ticket::WasActivated(bool &wasActivated)
{
    if (mWasActivated)
    {
        wasActivated = mWasActivated;
        return Errors::NO_ERROR;
    }

    int selectFromOpenOrdersError = SelectIfOpen("Checking if order is activated fallback open");
    if (selectFromOpenOrdersError != Errors::NO_ERROR)
    {
        // if we failed finding it we could have opened and closed the ticket between the last check.
        // If so we should check the closed tickets to see if our ticket is there
        int selectFromClosedOrdersError = SelectIfClosed("Checking if order is activated fallback closed");
        if (selectFromClosedOrdersError != Errors::NO_ERROR)
        {
            wasActivated = false;
            return selectFromClosedOrdersError;
        }
    }

    TicketType type = Type();
    mWasActivated = type == TicketType::Buy || type == TicketType::Sell;
    wasActivated = mWasActivated;

    return Errors::NO_ERROR;
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
            return Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return Errors::NO_ERROR;
        }
    }

    bool wasActivated = false;
    int wasActivatedError = WasActivated(wasActivated);
    if (wasActivatedError != Errors::NO_ERROR)
    {
        return wasActivatedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mActivatedSinceLastCheckCheckers.UpdateValueForKey(checker, wasActivated);
    wasActivatedSinceLastCheck = wasActivated;

    return Errors::NO_ERROR;
}

int Ticket::IsClosed(bool &closed)
{
    if (mIsClosed)
    {
        closed = true;
        return Errors::NO_ERROR;
    }

    int selectTicketError = SelectIfClosed("Checking if Closed");
    if (selectTicketError != Errors::NO_ERROR)
    {
        closed = false;
        return selectTicketError;
    }

    mIsClosed = true;
    closed = mIsClosed;

    return Errors::NO_ERROR;
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
            return Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return Errors::NO_ERROR;
        }
    }

    bool isClosed = false;
    int closedError = IsClosed(isClosed);
    if (closedError != Errors::NO_ERROR)
    {
        return closedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mClosedSinceLastCheckCheckers.UpdateValueForKey(checker, isClosed);
    wasClosedSinceLastCheck = isClosed;

    return Errors::NO_ERROR;
}

int Ticket::StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven)
{
    if (!mStopLossIsMovedToBreakEven)
    {
        int error = SelectIfOpen("Checking If Break Even");
        if (error != Errors::NO_ERROR)
        {
            return error;
        }

        // Need to normalize or else this will always return false on pairs that have more digits like currencies
        double stopLoss = NormalizeDouble(CurrentStopLoss(), Digits());
        double openPrice = NormalizeDouble(OpenPrice(), Digits());

        TicketType type = Type();
        if (type == TicketType::Buy)
        {
            mStopLossIsMovedToBreakEven = stopLoss >= openPrice;
        }
        else if (type == TicketType::Sell)
        {
            mStopLossIsMovedToBreakEven = stopLoss <= openPrice;
        }
    }

    stopLossIsMovedBreakEven = mStopLossIsMovedToBreakEven;
    return Errors::NO_ERROR;
}

void Ticket::SetPartials(List<double> &partialRRs, List<double> &partialPercents)
{
    for (int i = 0; i < partialRRs.Size(); i++)
    {
        Partial *partial = new Partial(partialRRs[i], partialPercents[i]);
        mPartials.Add(partial);
    }
}

static bool Ticket::EqualsTicketNumber(Ticket &ticket, int number)
{
    return ticket.Number() == number;
}