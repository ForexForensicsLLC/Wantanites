//+------------------------------------------------------------------+
//|                               TheSunriseShatterLiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\SingleTimeFrameTradeRecord.mqh>
#include <SummitCapital\Framework\EA\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class TheSunriseShatterLiquidationMB : public EA<SingleTimeFrameTradeRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    Ticket *mTicket;
    int mSetupType;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterLiquidationMB(int timeFrame, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                   MBTracker *&mbt);
    ~TheSunriseShatterLiquidationMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterLiquidationMB; }

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
};

TheSunriseShatterLiquidationMB::TheSunriseShatterLiquidationMB(int timeFrame, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                               MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterLiquidationMB/";
    mCSVFileName = "TheSunriseShatterLiquidationMB.csv";

    mMRFTS = mrfts;
    mMBT = mbt;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterLiquidationMB>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterLiquidationMB>(this);
}

TheSunriseShatterLiquidationMB::~TheSunriseShatterLiquidationMB()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterLiquidationMB::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterLiquidationMB>(this, mMBT);
}

bool TheSunriseShatterLiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterLiquidationMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBAfterMinROCBreak<TheSunriseShatterLiquidationMB>(this, mMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterLiquidationMB::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterLiquidationMB>(this, mMBT, mFirstMBInSetupNumber))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterLiquidationMB>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber, false))
    {
        return;
    }
}

void TheSunriseShatterLiquidationMB::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterLiquidationMB>(this, deletePendingOrder, error);
}

bool TheSunriseShatterLiquidationMB::Confirmation()
{
    return EAHelper::LiquidationMBZoneIsHolding<TheSunriseShatterLiquidationMB>(this, mMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber);
}

void TheSunriseShatterLiquidationMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterLiquidationMB>(this))
    {
        EAHelper::PlaceStopOrderForBreakOfMB<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
    }
}

void TheSunriseShatterLiquidationMB::ManagePendingTicket()
{
    EAHelper::CheckEditStopLossForBreakOfMB<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
}

void TheSunriseShatterLiquidationMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterLiquidationMB>(this, mMBT, mSecondMBInSetupNumber);
}

void TheSunriseShatterLiquidationMB::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::RecordOrderOpenData()
{
    EAHelper::RecordSingleTimeFrameRecordOpenData<TheSunriseShatterLiquidationMB>(this, mTimeFrame);
}

void TheSunriseShatterLiquidationMB::RecordOrderCloseData()
{
    EAHelper::RecordSingleTimeFrameRecordCloseData<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::Reset()
{
    EAHelper::ResetDoubleMBEA<TheSunriseShatterLiquidationMB>(this);
}