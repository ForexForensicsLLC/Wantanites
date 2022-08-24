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

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>
#include <SummitCapital\Framework\EA\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class TheSunriseShatterLiquidationMB : public EA<DefaultTradeRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    Ticket *mTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

public:
    TheSunriseShatterLiquidationMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
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

TheSunriseShatterLiquidationMB::TheSunriseShatterLiquidationMB(
    int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterLiquidationMB/";
    mCSVFileName = "TheSunriseShatterLiquidationMB.csv";

    mMRFTS = mrfts;
    mMBT = mbt;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

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
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterLiquidationMB>(this);
}

bool TheSunriseShatterLiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterLiquidationMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBAfterMinROCBreak<TheSunriseShatterLiquidationMB>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterLiquidationMB::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterLiquidationMB>(this))
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

    if (EAHelper::CheckBrokeLiquidationMBRangeEnd<TheSunriseShatterLiquidationMB>(this))
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
    return EAHelper::LiquidationMBZoneIsHolding<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterLiquidationMB>(this))
    {
        EAHelper::PlaceOrderOnLiquidationMB<TheSunriseShatterLiquidationMB>(this);
    }
}

void TheSunriseShatterLiquidationMB::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnBreakOfLiquidationMB<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::Reset()
{
    EAHelper::ResetDoubleMBEA<TheSunriseShatterLiquidationMB>(this);
}