//+------------------------------------------------------------------+
//|                               TheSunriseShatterLiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EA\EA.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

class TheSunriseShatterLiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterLiquidationMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
    ~TheSunriseShatterLiquidationMB();

    virtual int MagicNumber() { return mMBT.SetupType() == OP_BUY ? MagicNumbers::TheSunriseShatterBullishLiquidationMB : MagicNumbers::TheSunriseShatterBearishLiquidationMB; }

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManageCurrentPendingSetupTicket();
    virtual void ManageCurrentActiveSetupTicket();
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(int ticketIndex);
    virtual void CheckCurrentSetupTicket();
    virtual void CheckPreviousSetupTicket(int ticketIndex);
    virtual void RecordTicketOpenData();
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

TheSunriseShatterLiquidationMB::TheSunriseShatterLiquidationMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                                               double riskPercent, CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter,
                                                               CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMRFTS = mrfts;
    mMBT = mbt;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSunriseShatterLiquidationMB>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheSunriseShatterLiquidationMB, SingleTimeFrameEntryTradeRecord>(this);

    if (mMBT.SetupType() == OP_BUY)
    {
        EAHelper::FillSunriseShatterBullishMagicNumbers<TheSunriseShatterLiquidationMB>(this);
    }
    else
    {
        EAHelper::FillSunriseShatterBearishMagicNumbers<TheSunriseShatterLiquidationMB>(this);
    }
}

TheSunriseShatterLiquidationMB::~TheSunriseShatterLiquidationMB()
{
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

void TheSunriseShatterLiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterLiquidationMB>(this, mMBT, mFirstMBInSetupNumber))
    {
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterLiquidationMB>(this, true, true);
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterLiquidationMB>(this))
    {
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterLiquidationMB>(this, true, true);
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    // Broke Confirmation range end
    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber))
    {
        // don't delete the pending order since the setup held and continued
        EAHelper::InvalidateSetup<TheSunriseShatterLiquidationMB>(this, false, true);
        return;
    }
}

void TheSunriseShatterLiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheSunriseShatterLiquidationMB>(this, deletePendingOrder, true, error);
}

bool TheSunriseShatterLiquidationMB::Confirmation()
{
    return EAHelper::LiquidationMBZoneIsHolding<TheSunriseShatterLiquidationMB>(this, mMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber);
}

void TheSunriseShatterLiquidationMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterLiquidationMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingLiquidationSetupValidation<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
    }
}

void TheSunriseShatterLiquidationMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForLiquidationMBSetup<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
}

void TheSunriseShatterLiquidationMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterLiquidationMB>(this, mMBT, mSecondMBInSetupNumber);
}

bool TheSunriseShatterLiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheSunriseShatterLiquidationMB>(this, ticket);
}

void TheSunriseShatterLiquidationMB::ManagePreviousSetupTicket(int ticketIndex)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterLiquidationMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<TheSunriseShatterLiquidationMB>(this, ticketIndex);
}

void TheSunriseShatterLiquidationMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheSunriseShatterLiquidationMB>(this);
}

void TheSunriseShatterLiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterLiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheSunriseShatterLiquidationMB>(this, ticket, mTimeFrame);
}

void TheSunriseShatterLiquidationMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheSunriseShatterLiquidationMB>(this, error, additionalInformation);
}

void TheSunriseShatterLiquidationMB::Reset()
{
    EAHelper::ResetLiquidationMBSetup<TheSunriseShatterLiquidationMB>(this, true);
}