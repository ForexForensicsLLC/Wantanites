//+------------------------------------------------------------------+
//|                                        KataraSingleMB.mqh |
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

class KataraSingleMB : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;

public:
    KataraSingleMB(int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT);
    ~KataraSingleMB();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }

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

KataraSingleMB::KataraSingleMB(int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT)
    : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraSingleMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<KataraSingleMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<KataraSingleMB, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraSingleMB>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraSingleMB>(this);
    }
}

KataraSingleMB::~KataraSingleMB()
{
}

void KataraSingleMB::Run()
{
    EAHelper::RunDrawMBTs<KataraSingleMB>(this, mSetupMBT, mConfirmationMBT);
}

bool KataraSingleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<KataraSingleMB>(this);
}

void KataraSingleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBSetup<KataraSingleMB>(this, mSetupMBT,
                                                             mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber, mSetupType, true))
    {
        if (EAHelper::LiquidationMBZoneIsHolding<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber))
        {
            string additionalInformation = "";
            if (EAHelper::MBRetappedDeepestHoldingSetupZone<KataraSingleMB>(this, mFirstMBInSetupNumber, 0, mSetupMBT, mConfirmationMBT, additionalInformation) ||
                EAHelper::MBPushedFurtherIntoDeepestHoldingSetupZone<KataraSingleMB>(this, mFirstMBInSetupNumber, 0, mSetupMBT, mConfirmationMBT, additionalInformation))
            {
                if (EAHelper::CheckSetSingleMBSetup<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType, true))
                {
                    RecordError(-300, additionalInformation);
                    mHasSetup = true;
                }
            }
        }
    }
}

void KataraSingleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mSetupMBT, mLiquidationMBInSetupNumber, false))
    {
        return;
    }

    // Start of Confirmation TF First MB
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    // End of Confirmation TF First MB
    if (EAHelper::CheckBrokeMBRangeEnd<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        return;
    }
}

void KataraSingleMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<KataraSingleMB>(this, deletePendingOrder, false, error);

    EAHelper::ResetLiquidationMBSetup<KataraSingleMB>(this, false);
    EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);
}

bool KataraSingleMB::Confirmation()
{
    return EAHelper::MostRecentMBZoneIsHolding<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

void KataraSingleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<KataraSingleMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingMBValidation<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
    }
}

void KataraSingleMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

void KataraSingleMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

bool KataraSingleMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<KataraSingleMB>(this, ticket);
}

void KataraSingleMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<KataraSingleMB>(this, ticketIndex);
}

void KataraSingleMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<KataraSingleMB>(this);
}

void KataraSingleMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<KataraSingleMB>(this, ticketIndex);
}

void KataraSingleMB::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<KataraSingleMB>(this, 60);
}

void KataraSingleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<KataraSingleMB>(this, oldTicketIndex, newTicketNumber);
}

void KataraSingleMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<KataraSingleMB>(this, ticket, 1, 60);
}

void KataraSingleMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<KataraSingleMB>(this, error, additionalInformation);
}

void KataraSingleMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}