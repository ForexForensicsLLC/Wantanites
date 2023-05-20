//+------------------------------------------------------------------+
//|                                                           EA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Errors.mqh>
#include <Wantanites\Framework\Constants\EAStates.mqh>
#include <Wantanites\Framework\Objects\DataObjects\Tick.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\DataObjects\TradingSession.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Objects\TradeManager\TradeManager.mqh>

#include <Wantanites\Framework\Helpers\EAHelpers\EARunHelper.mqh>
#include <Wantanites\Framework\Helpers\EAHelpers\EAInitHelper.mqh>
#include <Wantanites\Framework\Helpers\EAHelpers\EASetupHelper.mqh>
#include <Wantanites\Framework\Helpers\EAHelpers\EAOrderHelper.mqh>
#include <Wantanites\Framework\Helpers\EAHelpers\EARecordHelper.mqh>

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
class EA
{
private:
    int mMagicNumber;
    SignalType mSetupType;

    Tick *mCurrentTick;
    int mBarCount;
    int mLastDay;

    string mEntrySymbol;
    ENUM_TIMEFRAMES mEntryTimeFrame;

    int mMaxTradesForEAGroup;

public:
    TradeManager *mTM;

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

    int mMaxTradesPerDay;
    double mRiskPercent;
    double mMaxSpreadPips;
    double mStopLossPaddingPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    List<int> *mEAGroupMagicNumbers;

    List<double> *mPartialRRs;
    List<double> *mPartialPercents;

    int mLastState;
    double mLargestAccountBalance; // should be defaulted to the starting capital of the account in case no trades have been taken yet

public:
    EA(int magicNumber, int setupType, int maxTradesForEAGroup, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter);
    ~EA();

    int MagicNumber() { return mMagicNumber; }
    SignalType SetupType() { return mSetupType; }
    double StopLossPaddingPips() { return mStopLossPaddingPips; }
    int MaxTradesForEAGroup() { return mMaxTradesForEAGroup; }

    string EntrySymbol() { return mEntrySymbol; }
    ENUM_TIMEFRAMES EntryTimeFrame() { return mEntryTimeFrame; }

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
    virtual void RecordError(string methodName, int error, string additionalInformation) = NULL;
    virtual bool ShouldReset() = NULL;
    virtual void Reset() = NULL;

    void AddPartial(double rr, double percent);
    void SetPartialCSVRecordWriter(CSVRecordWriter<TPartialRecord> *&writer) { mPartialCSVRecordWriter = writer; }

    void AddTradingSession(TradingSession *&ts) { mTradingSessions.Add(ts); }
};

template <typename TEntryRecord, typename TPartialRecord, typename TExitRecord, typename TErrorRecord>
EA::EA(int magicNumber, int setupType, int maxTradesForEAGroup, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
       CSVRecordWriter<TEntryRecord> *&entryCSVRecordWriter, CSVRecordWriter<TExitRecord> *&exitCSVRecordWriter, CSVRecordWriter<TErrorRecord> *&errorCSVRecordWriter)
{
    mTM = new TradeManager(magicNumber, 0);

    mMagicNumber = magicNumber;
    mSetupType = setupType;
    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEAGroupMagicNumbers = new List<int>();

    mMaxTradesForEAGroup = maxTradesForEAGroup;
    mMaxTradesPerDay = maxTradesPerDay;
    mRiskPercent = riskPercent;
    mMaxSpreadPips = maxSpreadPips;
    mStopLossPaddingPips = stopLossPaddingPips;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mCurrentTick = new Tick();
    mBarCount = ConstantValues::EmptyInt;
    mLastDay = ConstantValues::EmptyInt;

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
    delete mTM;

    delete mEAGroupMagicNumbers;

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

    EARunHelper::Run(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = DateTimeHelper::CurrentDay();
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