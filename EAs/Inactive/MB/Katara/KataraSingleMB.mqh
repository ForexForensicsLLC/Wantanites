//+------------------------------------------------------------------+
//|                                        KataraSingleMB.mqh |
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

class KataraSingleMB : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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

public:
    KataraSingleMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst);
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

KataraSingleMB::KataraSingleMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;
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
    // if (mSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;
    //     RecordError(-900, info);
    // }

    if (EAHelper::CheckSetLiquidationMBSetup<KataraSingleMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        bool isTrue = false;
        int error = EAHelper::LiquidationMBZoneIsHolding<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, isTrue);
        if (error != Errors::NO_ERROR)
        {
            EAHelper::InvalidateSetup<KataraSingleMB>(this, true, false);
            EAHelper::ResetLiquidationMBSetup<KataraSingleMB>(this, false);
            EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);
        }
        else if (isTrue)
        {
            string additionalInformation = "";
            if (EAHelper::SetupZoneIsValidForConfirmation<KataraSingleMB>(this, mFirstMBInSetupNumber, 0, additionalInformation))
            {
                if (EAHelper::CheckSetSingleMBSetup<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
                {
                    mHasSetup = true;
                }

                // if (mSetupMBsCreated < mConfirmationMBT.MBsCreated())
                // {
                //     string info = "Has Setup: " + mHasSetup + " First MB In Confirmation: " + mFirstMBInConfirmationNumber;

                //     additionalInformation += info;
                // }
            }

            // if (mSetupMBsCreated < mConfirmationMBT.MBsCreated())
            // {
            //     RecordError(-300, additionalInformation);
            // }
        }
    }

    // mSetupMBsCreated = mConfirmationMBT.MBsCreated();
}

void KataraSingleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;
    //     RecordError(-2000, info);
    // }

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1200, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }

        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraSingleMB>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<KataraSingleMB>(this, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1300, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraSingleMB>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<KataraSingleMB>(this, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);

        return;
    }

    // Start of Confirmation TF First MB
    // This will always cancel any pending orders
    if (EAHelper::CheckBrokeMBRangeStart<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1400, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraSingleMB>(this, true, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);

        return;
    }

    if (!mHasSetup)
    {
        // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();

        return;
    }

    // End of Confirmation TF First MB
    if (EAHelper::CheckBrokeMBRangeEnd<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1500, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraSingleMB>(this, false, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);

        return;
    }

    // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
}

void KataraSingleMB::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    // if (mInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     RecordError(-1100);
    //     mInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
    // }

    EAHelper::InvalidateSetup<KataraSingleMB>(this, deletePendingOrder, false, error);
}

bool KataraSingleMB::Confirmation()
{
    // if (mConfirmationMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;

    //     RecordError(-1800, info);
    //     mConfirmationMBsCreated = mConfirmationMBT.MBsCreated();
    // }
    bool hasConfirmation = false;
    int error = EAHelper::MostRecentMBZoneIsHolding<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, hasConfirmation);
    if (error != Errors::NO_ERROR)
    {
        EAHelper::InvalidateSetup<KataraSingleMB>(this, true, false);
        EAHelper::ResetSingleMBConfirmation<KataraSingleMB>(this, false);

        return false;
    }

    return hasConfirmation;
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