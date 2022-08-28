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
public:
    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;

    int mMaxTradesPerStrategy;
    int mStopLossPaddingPips;
    int mMaxSpreadPips;
    double mRiskPercent;

    int mStrategyMagicNumbers[];

    double mPartialRRs[];
    double mPartialPrices[];
    int mPartialPercents[];

    int mLastState;

public:
    EA(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent);
    ~EA();

    virtual void SetPartialPrice(double price, int percent);

    virtual int MagicNumber() = NULL;

    virtual void Run() = NULL;
    virtual bool AllowedToTrade() = NULL;
    virtual void CheckSetSetup() = NULL;
    virtual void CheckInvalidateSetup() = NULL;
    virtual void StopTrading(bool deletePendingOrder, int error) = NULL;
    virtual bool Confirmation() = NULL;
    virtual void PlaceOrders() = NULL;
    virtual void ManagePendingTicket() = NULL;
    virtual void ManageActiveTicket() = NULL;
    virtual void CheckTicket() = NULL;
    virtual void RecordOrderOpenData() = NULL;
    virtual void RecordOrderCloseData() = NULL;
    virtual void Reset() = NULL;

    void RecordError(int error);
};

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