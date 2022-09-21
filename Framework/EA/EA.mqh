//+------------------------------------------------------------------+
//|                                                           EA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\List.mqh>
#include <SummitCapital\Framework\Objects\TicketList.mqh>
#include <SummitCapital\Framework\Constants\Index.mqh>
#include <SummitCapital\Framework\Constants\EAStates.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
class EA
{
public:
    Ticket *mCurrentSetupTicket;
    TicketList *mPreviousSetupTickets;

    CSVRecordWriter<TEntryRecord> *mEntryCSVRecordWriter;
    CSVRecordWriter<TPartialRecord> *mPartialCSVRecordWriter;
    CSVRecordWriter<TExitRecord> *mExitCSVRecordWriter;
    CSVRecordWriter<TErrorRecord> *mErrorCSVRecordWriter;

    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;

    int mMaxCurrentSetupTradesAtOnce;
    int mMaxTradesPerDay;
    double mStopLossPaddingPips;
    double mMaxSpreadPips;
    double mRiskPercent;

    int mSetupType;
    int mStrategyMagicNumbers[];

    List<double> *mPartialRRs;
    List<double> *mPartialPercents;

    int mLastState;

public:
    EA(int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter);
    ~EA();

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
    virtual void RecordTicketCloseData(Ticket &ticket) = NULL;
    virtual void RecordError(int error, string additionalInformation) = NULL;
    virtual void Reset() = NULL;

    void AddPartial(double rr, double percent);
    void SetPartialCSVRecordWriter(CSVRecordWriter<TPartialRecord> *&writer) { mPartialCSVRecordWriter = writer; }
};

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
EA::EA(int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter)
{
    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mMaxCurrentSetupTradesAtOnce = maxCurrentSetupTradesAtOnce;
    mMaxTradesPerDay = maxTradesPerDay;
    mStopLossPaddingPips = stopLossPaddingPips;
    mMaxSpreadPips = maxSpreadPips;
    mRiskPercent = riskPercent;

    mEntryCSVRecordWriter = entryCSVRecordWriter;
    mExitCSVRecordWriter = exitCSVRecordWriter;
    mErrorCSVRecordWriter = errorCSVRecordWriter;

    mCurrentSetupTicket = new Ticket();
    mPreviousSetupTickets = new TicketList();

    mPartialRRs = new List<double>;
    mPartialPercents = new List<double>;
}

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
EA::~EA()
{
    delete mCurrentSetupTicket;
    delete mPreviousSetupTickets;

    delete mPartialRRs;
    delete mPartialPercents;
}

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
void EA::AddPartial(double rr, double percent)
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