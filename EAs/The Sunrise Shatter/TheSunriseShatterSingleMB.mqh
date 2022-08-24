//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingleMB.mqh |
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

class TheSunriseShatterSingleMB : public EA<DefaultTradeRecord>
{
public:
    Ticket *mTicket;
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mSetupType;
    int mFirstMBInSetupNumber;

public:
    TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterSingleMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterSingleMB; }

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

TheSunriseShatterSingleMB::TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                     MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterSingleMB/";
    mCSVFileName = "TheSunriseShatterSingleMB.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterSingleMB>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterSingleMB>(this);
}

TheSunriseShatterSingleMB::~TheSunriseShatterSingleMB()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterSingleMB::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterSingleMB>(this);
}

bool TheSunriseShatterSingleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterSingleMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBAfterMinROCBreak<TheSunriseShatterSingleMB>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterSingleMB::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterSingleMB>(this))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterSingleMB>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeSingleMBRangeEnd<TheSunriseShatterSingleMB>(this))
    {
        return;
    }
}

void TheSunriseShatterSingleMB::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterSingleMB>(this, deletePendingOrder, error);
}

bool TheSunriseShatterSingleMB::Confirmation()
{
    return EAHelper::FirstMBZoneIsHolding<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterSingleMB>(this))
    {
        EAHelper::PlaceOrderOnFirstMB<TheSunriseShatterSingleMB>(this);
    }
}

void TheSunriseShatterSingleMB::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnValidationOfFirstMB<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::Reset()
{
    EAHelper::ResetSingleMBEA<TheSunriseShatterSingleMB>(this);
}
