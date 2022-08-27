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

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\SingleTimeFrameTradeRecord.mqh>
#include <SummitCapital\Framework\EA\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class TheSunriseShatterSingleMB : public EA<SingleTimeFrameTradeRecord>
{
public:
    Ticket *mTicket;
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mSetupType;
    int mFirstMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterSingleMB(int timeFrame, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterSingleMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterSingleMB; }

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManagePendingTicket();
    virtual void ManageActiveTicket();
    virtual void CheckTicket();
    virtual void RecordOrderOpenData();
    virtual void RecordOrderCloseData();
    virtual void Reset();
};

TheSunriseShatterSingleMB::TheSunriseShatterSingleMB(int timeFrame, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                     MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterSingleMB/";
    mCSVFileName = "TheSunriseShatterSingleMB.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

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
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterSingleMB>(this, mMBT);
}

bool TheSunriseShatterSingleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterSingleMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetFirstMBAfterMinROCBreak<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterSingleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber))
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

    if (EAHelper::CheckBrokeMBRangeEnd<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber))
    {
        return;
    }
}

void TheSunriseShatterSingleMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheSunriseShatterSingleMB>(this, deletePendingOrder, true, error);
}

bool TheSunriseShatterSingleMB::Confirmation()
{
    return EAHelper::MostRecentMBZoneIsHolding<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
}

void TheSunriseShatterSingleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterSingleMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingMBValidation<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
    }
}

void TheSunriseShatterSingleMB::ManagePendingTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
}

void TheSunriseShatterSingleMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
}

void TheSunriseShatterSingleMB::CheckTicket()
{
    EAHelper::CheckTicket<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::RecordOrderOpenData()
{
    EAHelper::RecordSingleTimeFrameRecordOpenData<TheSunriseShatterSingleMB>(this, mTimeFrame);
}

void TheSunriseShatterSingleMB::RecordOrderCloseData()
{
    EAHelper::RecordSingleTimeFrameRecordCloseData<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::Reset()
{
    EAHelper::ResetSingleMBSetup<TheSunriseShatterSingleMB>(this, true);
}
