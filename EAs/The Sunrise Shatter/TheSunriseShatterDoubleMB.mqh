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

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\SingleTimeFrameTradeRecord.mqh>
#include <SummitCapital\Framework\EA\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class TheSunriseShatterDoubleMB : public EA
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterDoubleMB(int timeFrame, string directory, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
    ~TheSunriseShatterDoubleMB();

    virtual int MagicNumber() { return MagicNumbers::TheSunriseShatterDoubleMB; }

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
    virtual void RecordTicketCloseData();
    virtual void RecordError(int error);
    virtual void Reset();
};

TheSunriseShatterDoubleMB::TheSunriseShatterDoubleMB(int timeFrame, string directory, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips,
                                                     double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(directory, maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mMBT = mbt;
    mMRFTS = mrfts;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FillSunriseShatterMagicNumbers<TheSunriseShatterDoubleMB>(this);
    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSunriseShatterDoubleMB>(this);
}

TheSunriseShatterDoubleMB::~TheSunriseShatterDoubleMB()
{
    delete mMBT;
    delete mMRFTS;
}

void TheSunriseShatterDoubleMB::Run()
{
    EAHelper::RunDrawMBTAndMRFTS<TheSunriseShatterDoubleMB>(this, mMBT);
}

bool TheSunriseShatterDoubleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSunriseShatterDoubleMB>(this) && EAHelper::PastMinROCOpenTime<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetDoubleMBAfterMinROCBreak<TheSunriseShatterDoubleMB>(this, mMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterDoubleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (EAHelper::CheckBrokeMBRangeStart<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber))
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

    if (EAHelper::CheckBrokeMBRangeEnd<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber))
    {
        return;
    }
}

void TheSunriseShatterDoubleMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheSunriseShatterDoubleMB>(this, deletePendingOrder, true, error);
}

bool TheSunriseShatterDoubleMB::Confirmation()
{
    return EAHelper::MostRecentMBZoneIsHolding<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber);
}

void TheSunriseShatterDoubleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TheSunriseShatterDoubleMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingMBValidation<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber);
    }
}

void TheSunriseShatterDoubleMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber);
}

void TheSunriseShatterDoubleMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber);
}

bool TheSunriseShatterDoubleMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheSunriseShatterDoubleMB>(this, ticket);
}

void TheSunriseShatterDoubleMB::ManagePreviousSetupTicket(int ticketIndex)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterDoubleMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<TheSunriseShatterDoubleMB>(this, ticketIndex);
}

void TheSunriseShatterDoubleMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameTicketOpenData<TheSunriseShatterDoubleMB>(this, mTimeFrame);
}

void TheSunriseShatterDoubleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterDoubleMB::RecordTicketCloseData()
{
    EAHelper::RecordSingleTimeTicketCloseData<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::RecordError(int error)
{
    EAHelper::RecordDefaultErrorRecord<TheSunriseShatterDoubleMB>(this, error);
}

void TheSunriseShatterDoubleMB::Reset()
{
    EAHelper::ResetDoubleMBSetup<TheSunriseShatterDoubleMB>(this, true);
}