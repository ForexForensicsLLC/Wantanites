//+------------------------------------------------------------------+
//|                                        KataraSingleMBDoji.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\EA\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

class KataraSingleMBDoji : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    LiquidationSetupTracker *mLST;

    int mLastCheckedSetupMB;
    int mLastCheckedConfirmationMB;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

public:
    KataraSingleMBDoji(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst);
    ~KataraSingleMBDoji();

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

KataraSingleMBDoji::KataraSingleMBDoji(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mLST = lst;

    mSetupType = setupType;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraSingleMBDoji>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<KataraSingleMBDoji, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<KataraSingleMBDoji, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraSingleMBDoji>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraSingleMBDoji>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
}

KataraSingleMBDoji::~KataraSingleMBDoji()
{
}

void KataraSingleMBDoji::Run()
{
    EAHelper::RunDrawMBTs<KataraSingleMBDoji>(this, mSetupMBT, mConfirmationMBT);
}

bool KataraSingleMBDoji::AllowedToTrade()
{
    return EAHelper::BelowSpread<KataraSingleMBDoji>(this);
}

void KataraSingleMBDoji::CheckSetSetup()
{

    // if (EAHelper::CheckSetLiquidationMBSetup<KataraSingleMBDoji>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    // {
    //     bool isTrue = false;
    //     int error = EAHelper::LiquidationMBZoneIsHolding<KataraSingleMBDoji>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, isTrue);
    //     if (error != ERR_NO_ERROR)
    //     {
    //         EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, true, false);
    //         EAHelper::ResetLiquidationMBSetup<KataraSingleMBDoji>(this, false);
    //         EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);
    //     }
    //     else if (isTrue)
    //     {
    //         string additionalInformation = "";
    //         if (EAHelper::SetupZoneIsValidForConfirmation<KataraSingleMBDoji>(this, mFirstMBInSetupNumber, 0, additionalInformation))
    //         {
    //             if (EAHelper::CheckSetSingleMBSetup<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
    //             {
    //                 mHasSetup = true;
    //             }
    //         }
    //     }
    // }

    if (EAHelper::CheckSetSingleMBSetup<KataraSingleMBDoji>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        bool isTrue = false;
        int error = EAHelper::MostRecentMBZoneIsHolding<KataraSingleMBDoji>(this, mSetupMBT, mFirstMBInSetupNumber, isTrue);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, true, false);
            EAHelper::ResetSingleMBSetup<KataraSingleMBDoji>(this, false);
            EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);
        }
        else if (isTrue)
        {
            string additionalInformation = "";
            if (EAHelper::SetupZoneIsValidForConfirmation<KataraSingleMBDoji>(this, mFirstMBInSetupNumber, 0, additionalInformation))
            {
                if (EAHelper::CheckSetSingleMBSetup<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void KataraSingleMBDoji::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMBDoji>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<KataraSingleMBDoji>(this, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeEnd<KataraSingleMBDoji>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<KataraSingleMBDoji>(this, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);

        return;
    }

    // Start of Confirmation TF First MB
    // This will always cancel any pending orders
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, true, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);

        return;
    }

    if (!mHasSetup)
    {

        return;
    }

    // End of Confirmation TF First MB
    if (EAHelper::CheckBrokeMBRangeEnd<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, false, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);

        return;
    }
}

void KataraSingleMBDoji::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    RecordError(-44);
    EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool KataraSingleMBDoji::Confirmation()
{
    int currentBars = iBars(Symbol(), 1);

    bool hasConfirmation = false;
    if (currentBars > mBarCount)
    {
        int error = EAHelper::EngulfingCandleInZone<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, hasConfirmation);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<KataraSingleMBDoji>(this, true, false);
            EAHelper::ResetSingleMBConfirmation<KataraSingleMBDoji>(this, false);

            return false;
        }

        mBarCount = currentBars;
    }

    return hasConfirmation || mCurrentSetupTicket.Number() != EMPTY;
    // MBState *tempMBState;
    // if (!mConfirmationMBT.GetNthMostRecentMB(0, tempMBState))
    // {
    //     return false;
    // }

    // bool confirmation = false;
    // if (mSetupType == OP_BUY)
    // {
    //     confirmation = iHigh(Symbol(), 1, 0) > iHigh(Symbol(), 1, tempMBState.HighIndex());
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     confirmation = iLow(Symbol(), 1, 0) < iLow(Symbol(), 1, tempMBState.LowIndex());
    // }

    // return confirmation;
}

void KataraSingleMBDoji::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<KataraSingleMBDoji>(this))
    {
        EAHelper::PlaceStopOrderForCandelBreak<KataraSingleMBDoji>(this, Symbol(), 1, 1);
        mEntryCandleTime = iTime(Symbol(), 1, 1);
    }
}

void KataraSingleMBDoji::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckBrokePastCandle<KataraSingleMBDoji>(this, Symbol(), 1, mSetupType, mEntryCandleTime);
}

void KataraSingleMBDoji::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraSingleMBDoji>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

bool KataraSingleMBDoji::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<KataraSingleMBDoji>(this, ticket);
}

void KataraSingleMBDoji::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<KataraSingleMBDoji>(this, ticketIndex);
}

void KataraSingleMBDoji::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<KataraSingleMBDoji>(this);
}

void KataraSingleMBDoji::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<KataraSingleMBDoji>(this, ticketIndex);
}

void KataraSingleMBDoji::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<KataraSingleMBDoji>(this, 60);
}

void KataraSingleMBDoji::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<KataraSingleMBDoji>(this, oldTicketIndex, newTicketNumber);
}

void KataraSingleMBDoji::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<KataraSingleMBDoji>(this, ticket, 1, 60);
}

void KataraSingleMBDoji::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<KataraSingleMBDoji>(this, error, additionalInformation);
}

void KataraSingleMBDoji::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}