//+------------------------------------------------------------------+
//|                                                       Double.mqh |
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

class TheSunriseShatterDoubleMBC : public EAC<DefaultTradeRecord>
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
    TheSunriseShatterDoubleMBC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                               MBTracker *&mbt);
    ~TheSunriseShatterDoubleMBC();

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

static int TheSunriseShatterDoubleMBC::MagicNumber = 10004;

TheSunriseShatterDoubleMBC::TheSunriseShatterDoubleMBC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                                       MBTracker *&mbt) : EAC(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterDoubleMBC/";
    mCSVFileName = "TheSunriseShatterDoubleMBC.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterDoubleMBC>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterDoubleMBC>(this);
}

TheSunriseShatterDoubleMBC::~TheSunriseShatterDoubleMBC()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterDoubleMBC::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterDoubleMBC>(this);
}

bool TheSunriseShatterDoubleMBC::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterDoubleMBC>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::CheckSetSetup()
{
    if (EAHelper::CheckSetDoubleMBAfterMinROCBreak<TheSunriseShatterDoubleMBC>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterDoubleMBC::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterDoubleMBC>(this))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterDoubleMBC>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeDoubleMBRangeEnd<TheSunriseShatterDoubleMBC>(this))
    {
        return;
    }
}

void TheSunriseShatterDoubleMBC::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterDoubleMBC>(this, deletePendingOrder, error);
}

bool TheSunriseShatterDoubleMBC::Confirmation()
{
    return EAHelper::SecondMBZoneIsHolding<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterDoubleMBC>(this))
    {
        EAHelper::PlaceOrderOnSecondMB<TheSunriseShatterDoubleMBC>(this);
    }
}

void TheSunriseShatterDoubleMBC::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnValidationOfSecondMB<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterDoubleMBC>(this);
}
void TheSunriseShatterDoubleMBC::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterDoubleMBC>(this);
}

void TheSunriseShatterDoubleMBC::Reset()
{
    EAHelper::ResetDoubleMBEA<TheSunriseShatterDoubleMBC>(this);
}