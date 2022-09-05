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

class TheSunriseShatterLiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, DefaultErrorRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterLiquidationMB(int timeFrame, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
    ~TheSunriseShatterLiquidationMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterLiquidationMB; }

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
    virtual void RecordTicketCloseData(int ticketNumber);
    virtual void RecordError(int error);
    virtual void Reset();
};

TheSunriseShatterLiquidationMB::TheSunriseShatterLiquidationMB(int timeFrame, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips,
                                                               double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mMRFTS = mrfts;
    mMBT = mbt;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterLiquidationMB>(this);
    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSunriseShatterLiquidationMB>(this);
}

TheSunriseShatterLiquidationMB::~TheSunriseShatterLiquidationMB()
{
    delete mMBT;
    delete mMRFTS;
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
        EAHelper::PlaceStopOrderForBreakOfMB<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
    }
}

void TheSunriseShatterLiquidationMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForBreakOfMB<TheSunriseShatterLiquidationMB>(this, mMBT, mLiquidationMBInSetupNumber);
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
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheSunriseShatterLiquidationMB>(this, mTimeFrame);
}

void TheSunriseShatterLiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterLiquidationMB::RecordTicketCloseData(int ticketNumber)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheSunriseShatterLiquidationMB>(this, ticketNumber);
}

void TheSunriseShatterLiquidationMB::RecordError(int error)
{
    EAHelper::RecordDefaultErrorRecord<TheSunriseShatterLiquidationMB>(this, error);
}

void TheSunriseShatterLiquidationMB::Reset()
{
    EAHelper::ResetLiquidationMBSetup<TheSunriseShatterLiquidationMB>(this, true);
}