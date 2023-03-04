//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingleMB.mqh |
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

class TheSunriseShatterSingleMB : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mTimeFrame;

public:
    TheSunriseShatterSingleMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
    ~TheSunriseShatterSingleMB();

    virtual int MagicNumber() { return mMBT.SetupType() == OP_BUY ? MagicNumbers::TheSunriseShatterBullishSingleMB : MagicNumbers::TheSunriseShatterBearishSingleMB; }

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

TheSunriseShatterSingleMB::TheSunriseShatterSingleMB(int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                                     double riskPercent, CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mMRFTS = mrfts;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mTimeFrame = timeFrame;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSunriseShatterSingleMB>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheSunriseShatterSingleMB, SingleTimeFrameEntryTradeRecord>(this);

    if (mMBT.SetupType() == OP_BUY)
    {
        EAHelper::FillSunriseShatterBullishMagicNumbers<TheSunriseShatterSingleMB>(this);
    }
    else
    {
        EAHelper::FillSunriseShatterBearishMagicNumbers<TheSunriseShatterSingleMB>(this);
    }
}

TheSunriseShatterSingleMB::~TheSunriseShatterSingleMB()
{
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
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterSingleMB>(this, true, true);
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    if (EAHelper::CheckCrossedOpenPriceAfterMinROC<TheSunriseShatterSingleMB>(this))
    {
        // delete any pending orders and stop trading
        EAHelper::InvalidateSetup<TheSunriseShatterSingleMB>(this, true, true);
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeMBRangeEnd<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber))
    {
        // don't delete the pending order since the setup held and continued
        EAHelper::InvalidateSetup<TheSunriseShatterSingleMB>(this, false, true);
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

void TheSunriseShatterSingleMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
}

void TheSunriseShatterSingleMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<TheSunriseShatterSingleMB>(this, mMBT, mFirstMBInSetupNumber);
}

bool TheSunriseShatterSingleMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheSunriseShatterSingleMB>(this, ticket);
}

void TheSunriseShatterSingleMB::ManagePreviousSetupTicket(int ticketIndex)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterSingleMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<TheSunriseShatterSingleMB>(this, ticketIndex);
}

void TheSunriseShatterSingleMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheSunriseShatterSingleMB>(this);
}

void TheSunriseShatterSingleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    // This Strategy doesn't take any partials
}

void TheSunriseShatterSingleMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheSunriseShatterSingleMB>(this, ticket, mTimeFrame);
}

void TheSunriseShatterSingleMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheSunriseShatterSingleMB>(this, error, additionalInformation);
}

void TheSunriseShatterSingleMB::Reset()
{
    EAHelper::ResetSingleMBSetup<TheSunriseShatterSingleMB>(this, true);
}
