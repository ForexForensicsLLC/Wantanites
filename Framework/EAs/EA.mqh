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

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

template <typename TRecord>
class EA : public CSVRecordWriter<TRecord>
{
protected:
    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;
    int mLastState;

    int mMaxTradesPerStrategy;
    int mStopLossPaddingPips;
    int mMaxSpreadPips;
    double mRiskPercent;

    int mStrategyMagicNumbers[];

    double mPartialRRs[];
    double mPartialPrices[];
    int mPartialPercents[];

public:
    EA(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent);
    ~EA();

    bool IsDoneTrading() { return mStopTrading; }
    bool HasSetup() { return mHasSetup; }
    bool WasReset() { return mWasReset; }
    int GetLastState() { return mLastState; }

    int MaxTradesPerStrategy() { return mMaxTradesPerStrategy; }
    int StopLossPaddingPips() { return mStopLossPaddingPips; }
    int MaxSpreadPips() { return mMaxSpreadPips; }
    double RiskPercent() { return mRiskPercent; }

    virtual void SetPartialPrice(double price, int percent);

    void StrategyMagicNumbers(int &strategyMagicNumbers[]);

    virtual void FillStrategyMagicNumber();
    virtual void SetActiveTickets();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void RecordOrderCloseData();

    virtual void CheckTicket();
    virtual void Manage();
    virtual void CheckStopTrading();
    virtual void StopTrading(bool deletePendingOrder, int error);
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();

    void RecordError(int error);
};

template <typename TRecord>
void EA::StrategyMagicNumbers(int &strategyMagicNumbers[])
{
    if (ArraySize(strategyMagicNumbers) != ArraySize(mStrategyMagicNumbers))
    {
        return;
    }

    ArrayCopy(strategyMagicNumbers, mStrategyMagicNumbers);
}

template <typename TRecord>
EA::EA(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent)
{
    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mMaxTradesPerStrategy = maxTradesPerStrategy;
    mStopLossPaddingPips = stopLossPaddingPips;
    mMaxSpreadPips = maxSpreadPips;
    mRiskPercent = riskPercent;
}

template <typename TRecord>
EA::~EA()
{
}

template <typename TRecord>
void EA::RecordError(int error)
{
    PendingRecord.LastState = mLastState;
    PendingRecord.Error = error;

    string imageName = ScreenShotHelper::TryTakeScreenShot(mDirectory);
    PendingRecord.ErrorImage = imageName;

    CSVRecordWriter<TRecord>::Write();
}