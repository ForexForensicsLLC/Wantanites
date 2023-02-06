//+------------------------------------------------------------------+
//|                                                           EA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\DataObjects\Tick.mqh>
#include <SummitCapital\Framework\Objects\DataStructures\List.mqh>
#include <SummitCapital\Framework\Constants\Index.mqh>
#include <SummitCapital\Framework\Constants\EAStates.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\Objects\DataObjects\TradingSession.mqh>

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
class EA
{
private:
    int mMagicNumber;
    int mSetupType;

    Tick *mCurrentTick;
    int mBarCount;
    int mLastDay;

public:
    ObjectList<Ticket> *mCurrentSetupTickets;
    ObjectList<Ticket> *mPreviousSetupTickets;
    ObjectList<TradingSession> *mTradingSessions;

    CSVRecordWriter<TEntryRecord> *mEntryCSVRecordWriter;
    CSVRecordWriter<TPartialRecord> *mPartialCSVRecordWriter;
    CSVRecordWriter<TExitRecord> *mExitCSVRecordWriter;
    CSVRecordWriter<TErrorRecord> *mErrorCSVRecordWriter;

    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;

    string mEntrySymbol;
    int mEntryTimeFrame;

    int mMaxCurrentSetupTradesAtOnce;
    int mMaxTradesPerDay;
    double mRiskPercent;
    double mMaxSpreadPips;
    double mStopLossPaddingPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    int mStrategyMagicNumbers[];

    List<double> *mPartialRRs;
    List<double> *mPartialPercents;

    int mLastState;
    double mLargestAccountBalance; // should be defaulted to the starting capital of the account in case no trades have been taken yet

public:
    EA(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter);
    ~EA();

    int MagicNumber() { return mMagicNumber; }
    int SetupType() { return mSetupType; }

    Tick *CurrentTick() { return mCurrentTick; }
    int BarCount() { return mBarCount; }
    int LastDay() { return mLastDay; }

    virtual double RiskPercent() = NULL;
    virtual void PreRun() = NULL;
    void Run();
    virtual bool AllowedToTrade() = NULL;
    virtual void CheckSetSetup() = NULL;
    virtual void CheckInvalidateSetup() = NULL;
    virtual void InvalidateSetup(bool deletePendingOrder, int error) = NULL;
    virtual bool Confirmation() = NULL;
    virtual void PlaceOrders() = NULL;
    virtual void PreManageTickets() = NULL;
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket) = NULL;
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket) = NULL;
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket) = NULL;
    virtual void ManagePreviousSetupTicket(Ticket &ticket) = NULL;
    virtual void CheckCurrentSetupTicket(Ticket &ticket) = NULL;
    virtual void CheckPreviousSetupTicket(Ticket &ticket) = NULL;
    virtual void RecordTicketOpenData(Ticket &ticket) = NULL;
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber) = NULL;
    virtual void RecordTicketCloseData(Ticket &ticket) = NULL;
    virtual void RecordError(int error, string additionalInformation) = NULL;
    virtual bool ShouldReset() = NULL;
    virtual void Reset() = NULL;

    void AddPartial(double rr, double percent);
    void SetPartialCSVRecordWriter(CSVRecordWriter<TPartialRecord> *&writer) { mPartialCSVRecordWriter = writer; }

    void AddTradingSession(int hourStart, int minuteStart, int inclusiveHourEnd, int inclusiveMinuteEnd);
};

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
EA::EA(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter)
{
    mMagicNumber = magicNumber;
    mSetupType = setupType;
    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mMaxCurrentSetupTradesAtOnce = maxCurrentSetupTradesAtOnce;
    mMaxTradesPerDay = maxTradesPerDay;
    mRiskPercent = riskPercent;
    mMaxSpreadPips = maxSpreadPips;
    mStopLossPaddingPips = stopLossPaddingPips;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mCurrentTick = new Tick();
    mBarCount = EMPTY;
    mLastDay = EMPTY;

    mEntryCSVRecordWriter = entryCSVRecordWriter;
    mExitCSVRecordWriter = exitCSVRecordWriter;
    mErrorCSVRecordWriter = errorCSVRecordWriter;

    mCurrentSetupTickets = new ObjectList<Ticket>();
    mPreviousSetupTickets = new ObjectList<Ticket>();
    mTradingSessions = new ObjectList<TradingSession>();

    mPartialRRs = new List<double>;
    mPartialPercents = new List<double>;
}

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
EA::~EA()
{
    delete mCurrentSetupTickets;
    delete mPreviousSetupTickets;

    delete mCurrentTick;

    delete mTradingSessions;

    delete mPartialRRs;
    delete mPartialPercents;
}

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
void EA::Run()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        mCurrentTick.SetStatus(TickStatus::Invalid);
    }
    else
    {
        mCurrentTick = currentTick;
        mCurrentTick.SetStatus(TickStatus::Valid);
    }

    EAHelper::Run(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
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

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
void EA::AddTradingSession(int hourStart, int minuteStart, int inclusiveHourEnd, int inclusiveMinuteEnd)
{
    TradingSession *ts = new TradingSession(hourStart, minuteStart, inclusiveHourEnd, inclusiveMinuteEnd);
    mTradingSessions.Add(ts);
}