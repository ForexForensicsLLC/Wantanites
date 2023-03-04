//+------------------------------------------------------------------+
//|                                                       Double.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class TheSunriseShatterDoubleMB : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    int mTimeFrame;

public:
    TheSunriseShatterDoubleMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&closeCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
    ~TheSunriseShatterDoubleMB();

    virtual int MagicNumber() { return mMBT.SetupType() == OP_BUY ? MagicNumbers::TheSunriseShatterBullishDoubleMB : MagicNumbers::TheSunriseShatterBearishDoubleMB; }

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

TheSunriseShatterDoubleMB::TheSunriseShatterDoubleMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                                     double riskPercent, CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mMRFTS = mrfts;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSunriseShatterDoubleMB>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheSunriseShatterDoubleMB, SingleTimeFrameEntryTradeRecord>(this);

    if (mMBT.SetupType() == OP_BUY)
    {
        EAHelper::FillSunriseShatterBullishMagicNumbers<TheSunriseShatterDoubleMB>(this);
    }
    else
    {
        EAHelper::FillSunriseShatterBearishMagicNumbers<TheSunriseShatterDoubleMB>(this);
    }
}

TheSunriseShatterDoubleMB::~TheSunriseShatterDoubleMB()
{
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
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterDoubleMB>(this, true, true);
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterDoubleMB>(this))
    {
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterDoubleMB>(this, true, true);
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    // broke confirmation range end
    if (EAHelper::CheckBrokeMBRangeEnd<TheSunriseShatterDoubleMB>(this, mMBT, mSecondMBInSetupNumber))
    {
        // don't delete the pending order since the setup held and continued
        EAHelper::InvalidateSetup<TheSunriseShatterDoubleMB>(this, false, true);
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
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheSunriseShatterDoubleMB>(this);
}

void TheSunriseShatterDoubleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterDoubleMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheSunriseShatterDoubleMB>(this, ticket, mTimeFrame);
}

void TheSunriseShatterDoubleMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheSunriseShatterDoubleMB>(this, error, additionalInformation);
}

void TheSunriseShatterDoubleMB::Reset()
{
    EAHelper::ResetDoubleMBSetup<TheSunriseShatterDoubleMB>(this, true);
}