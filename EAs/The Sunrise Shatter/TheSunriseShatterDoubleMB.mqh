//+------------------------------------------------------------------+
//|                                                       Double.mqh |
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

class TheSunriseShatterDoubleMB : public EA<DefaultTradeRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    Ticket *mTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

public:
    TheSunriseShatterDoubleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterDoubleMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterDoubleMB; }

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

TheSunriseShatterDoubleMB::TheSunriseShatterDoubleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                                     MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterDoubleMB/";
    mCSVFileName = "TheSunriseShatterDoubleMB.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterDoubleMB>(this);
    EAHelper::SetSingleActiveTicket<TheSunriseShatterDoubleMB>(this);
}

TheSunriseShatterDoubleMB::~TheSunriseShatterDoubleMB()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterDoubleMB::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterDoubleMB>(this);
}

bool TheSunriseShatterDoubleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterDoubleMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetDoubleMBAfterMinROCBreak<TheSunriseShatterDoubleMB>(this))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterDoubleMB::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeRangeStart<TheSunriseShatterDoubleMB>(this))
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterDoubleMB>(this))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeDoubleMBRangeEnd<TheSunriseShatterDoubleMB>(this))
    {
        return;
    }
}

void TheSunriseShatterDoubleMB::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::StopTrading<TheSunriseShatterDoubleMB>(this, deletePendingOrder, error);
}

bool TheSunriseShatterDoubleMB::Confirmation()
{
    return EAHelper::SecondMBZoneIsHolding<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterDoubleMB>(this))
    {
        EAHelper::PlaceOrderOnSecondMB<TheSunriseShatterDoubleMB>(this);
    }
}

void TheSunriseShatterDoubleMB::ManagePendingTicket()
{
    EAHelper::CheckEditPendingOrderStopLossOnValidationOfSecondMB<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterDoubleMB>(this);
}
void TheSunriseShatterDoubleMB::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::RecordOrderOpenData()
{
    EAHelper::RecordOrderOpenData<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::RecordOrderCloseData()
{
    EAHelper::RecordOrderCloseData<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::Reset()
{
    EAHelper::ResetDoubleMBEA<TheSunriseShatterDoubleMB>(this);
}