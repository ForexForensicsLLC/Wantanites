//+------------------------------------------------------------------+
//|                                                           EAC.mqh |
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
class EAC : public CSVRecordWriter<TRecord>
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
    EAC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent);
    ~EAC();

    virtual void SetPartialPrice(double price, int percent);

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckStopTrading();
    virtual void StopTrading(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManagePendingTicket();
    virtual void ManageActiveTicket();
    virtual void CheckTicket();
    virtual void RecordOrderOpenData();
    virtual void RecordOrderCloseData();
    virtual void Reset();

    void RecordError(int error);
};

template <typename TRecord>
EAC::EAC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent)
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
EAC::~EAC()
{
}

template <typename TRecord>
void EAC::RecordError(int error)
{
    PendingRecord.LastState = mLastState;
    PendingRecord.Error = error;

    string imageName = ScreenShotHelper::TryTakeScreenShot(mDirectory);
    PendingRecord.ErrorImage = imageName;

    CSVRecordWriter<TRecord>::Write();
}