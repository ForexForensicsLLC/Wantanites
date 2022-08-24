//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingleMBC.mqh |
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

class TheSunriseShatterSingleMBC : public EAC<DefaultTradeRecord>
{
public:
    static int MagicNumber;

    Ticket *mTicket;
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mSetupType;
    int mFirstMBInSetupNumber;

public:
    TheSunriseShatterSingleMBC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                               MBTracker *&mbt);
    ~TheSunriseShatterSingleMBC();

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

static int TheSunriseShatterSingleMBC::MagicNumber = 10003;

TheSunriseShatterSingleMBC::TheSunriseShatterSingleMBC(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                       MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EAC(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterSingleMBC/";
    mCSVFileName = "TheSunriseShatterSingleMBC.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterSingleMBC>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterSingleMBC>(this);
}

TheSunriseShatterSingleMBC::~TheSunriseShatterSingleMBC()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterSingleMBC::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterSingleMBC>(this);
}

bool TheSunriseShatterSingleMBC::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterSingleMBC>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBAfterMinROCBreak<TheSunriseShatterSingleMBC>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterSingleMBC::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterSingleMBC>(this))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterSingleMBC>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeSingleMBRangeEnd<TheSunriseShatterSingleMBC>(this))
    {
        return;
    }
}

void TheSunriseShatterSingleMBC::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterSingleMBC>(this, deletePendingOrder, error);
}

bool TheSunriseShatterSingleMBC::Confirmation()
{
    return EAHelper::FirstMBZoneIsHolding<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterSingleMBC>(this))
    {
        EAHelper::PlaceOrderOnFirstMB<TheSunriseShatterSingleMBC>(this);
    }
}

void TheSunriseShatterSingleMBC::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnValidationOfFirstMB<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterSingleMBC>(this);
}

void TheSunriseShatterSingleMBC::Reset()
{
    EAHelper::ResetSingleMBEA<TheSunriseShatterSingleMBC>(this);
}
