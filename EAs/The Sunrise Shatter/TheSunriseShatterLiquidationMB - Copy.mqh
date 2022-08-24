//+------------------------------------------------------------------+
//|                               TheSunriseShatterLiquidationMBC.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA - Copy.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class TheSunriseShatterLiquidationMBC : public EAC<DefaultTradeRecord>
{
public:
    static int MagicNumber;

    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    Ticket *mTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

public:
    TheSunriseShatterLiquidationMBC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                    MBTracker *&mbt);
    ~TheSunriseShatterLiquidationMBC();

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

static int TheSunriseShatterLiquidationMBC::MagicNumber = 10005;

TheSunriseShatterLiquidationMBC::TheSunriseShatterLiquidationMBC(
    int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EAC(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterLiquidationMBC/";
    mCSVFileName = "TheSunriseShatterLiquidationMBC.csv";

    mMRFTS = mrfts;
    mMBT = mbt;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterLiquidationMBC>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterLiquidationMBC>(this);
}

TheSunriseShatterLiquidationMBC::~TheSunriseShatterLiquidationMBC()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterLiquidationMBC::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterLiquidationMBC>(this);
}

bool TheSunriseShatterLiquidationMBC::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterLiquidationMBC>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBAfterMinROCBreak<TheSunriseShatterLiquidationMBC>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterLiquidationMBC::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterLiquidationMBC>(this))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterLiquidationMBC>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeLiquidationMBRangeEnd<TheSunriseShatterLiquidationMBC>(this))
    {
        return;
    }
}

void TheSunriseShatterLiquidationMBC::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterLiquidationMBC>(this, deletePendingOrder, error);
}

bool TheSunriseShatterLiquidationMBC::Confirmation()
{
    return EAHelper::LiquidationMBZoneIsHolding<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterLiquidationMBC>(this))
    {
        EAHelper::PlaceOrderOnLiquidationMB<TheSunriseShatterLiquidationMBC>(this);
    }
}

void TheSunriseShatterLiquidationMBC::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnBreakOfLiquidationMB<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterLiquidationMBC>(this);
}

void TheSunriseShatterLiquidationMBC::Reset()
{
    EAHelper::ResetDoubleMBEA<TheSunriseShatterLiquidationMBC>(this);
}