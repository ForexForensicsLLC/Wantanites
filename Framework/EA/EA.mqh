//+------------------------------------------------------------------+
//|                                                           EA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\EAStates.mqh>
#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVTradeRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

#include <SummitCapital\Framework\Objects\List.mqh>

class EA
{
public:
    Ticket *mCurrentSetupTicket;
    TicketList *mPreviousSetupTickets;

    CSVTradeRecordWriter *mTradeRecordRecorder;
    CSVRecordWriter *mErrorRecordRecorder;

    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;

    int mMaxTradesPerStrategy;
    double mStopLossPaddingPips;
    double mMaxSpreadPips;
    double mRiskPercent;

    int mSetupType;
    int mStrategyMagicNumbers[];

    List<double> mPartialRRs;
    List<double> mPartialPercents;

    int mLastState;

public:
    EA(string directory, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent);
    ~EA();

    virtual void SetRRPartial(double rr, double percent);

    virtual int MagicNumber() = NULL;

    virtual void Run() = NULL;
    virtual bool AllowedToTrade() = NULL;
    virtual void CheckSetSetup() = NULL;
    virtual void CheckInvalidateSetup() = NULL;
    virtual void InvalidateSetup(bool deletePendingOrder, int error) = NULL;
    virtual bool Confirmation() = NULL;
    virtual void PlaceOrders() = NULL;
    virtual void ManageCurrentPendingSetupTicket() = NULL;
    virtual void ManageCurrentActiveSetupTicket() = NULL;
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket) = NULL;
    virtual void ManagePreviousSetupTicket(int ticketIndex) = NULL;
    virtual void CheckCurrentSetupTicket() = NULL;
    virtual void CheckPreviousSetupTicket(int ticketIndex) = NULL;
    virtual void RecordTicketOpenData() = NULL;
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber) = NULL;
    virtual void RecordTicketCloseData() = NULL;
    virtual void RecordError(int error) = NULL;
    virtual void Reset() = NULL;
};

EA::EA(string directory, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent)
{
    mTradeRecordRecorder = new CSVTradeRecordWriter(directory + "Trades/", "Trades.csv");
    mErrorRecordRecorder = new CSVRecordWriter(directory + "Errors/", "Errors.csv");

    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mMaxTradesPerStrategy = maxTradesPerStrategy;
    mStopLossPaddingPips = stopLossPaddingPips;
    mMaxSpreadPips = maxSpreadPips;
    mRiskPercent = riskPercent;

    mCurrentSetupTicket = new Ticket();
    mPartialRRs = new List<double>;
    mPartialPercents = new List<double>;
}

EA::~EA()
{
    delete mCurrentSetupTicket;
    delete mPreviousSetupTickets;

    delete mTradeRecordRecorder;
    delete mErrorRecordRecorder;
}

void EA::SetRRPartial(double rr, double percent)
{
    int partials = mPartialRRs.Size();

    // Can't incluce a partial that is less than the one before it
    if (partials > 0)
    {
        if (rr <= mPartialRRs[partials - 1])
        {
            return;
        }
    }

    mPartialRRs.Add(rr);
    mPartialPercents.Add(percent);
}