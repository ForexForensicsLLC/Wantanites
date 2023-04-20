//+------------------------------------------------------------------+
//|                                        KataraDoubleMB.mqh |
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

class KataraDoubleMB : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    LiquidationSetupTracker *mLST;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

public:
    KataraDoubleMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst);
    ~KataraDoubleMB();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraDoubleMB : MagicNumbers::BearishKataraDoubleMB; }

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

KataraDoubleMB::KataraDoubleMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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
    mSecondMBInConfirmationNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraDoubleMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<KataraDoubleMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<KataraDoubleMB, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraDoubleMB>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraDoubleMB>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;
}

KataraDoubleMB::~KataraDoubleMB()
{
}

void KataraDoubleMB::Run()
{
    EAHelper::RunDrawMBTs<KataraDoubleMB>(this, mSetupMBT, mConfirmationMBT);
}

bool KataraDoubleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<KataraDoubleMB>(this);
}

void KataraDoubleMB::CheckSetSetup()
{
    // if (mSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;

    //     RecordError(-900, info);
    // }

    if (EAHelper::CheckSetLiquidationMBSetup<KataraDoubleMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        bool isTrue = false;
        int error = EAHelper::LiquidationMBZoneIsHolding<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, isTrue);
        if (error != Errors::NO_ERROR)
        {
            EAHelper::InvalidateSetup<KataraDoubleMB>(this, true, false);
            EAHelper::ResetLiquidationMBSetup<KataraDoubleMB>(this, false);
            EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);
        }
        else if (isTrue)
        {
            string additionalInformation = "";
            if (EAHelper::SetupZoneIsValidForConfirmation<KataraDoubleMB>(this, mFirstMBInSetupNumber, 1, additionalInformation))
            {
                if (EAHelper::CheckSetDoubleMBSetup<KataraDoubleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSecondMBInConfirmationNumber, mSetupType))
                {
                    mHasSetup = true;
                }

                // if (mSetupMBsCreated < mConfirmationMBT.MBsCreated())
                // {
                //     string info = "Has Setup: " + mHasSetup + " First MB In Confirmation: " + mFirstMBInConfirmationNumber +
                //                   " Second MB In Confirmation: " + mSecondMBInConfirmationNumber;

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

void KataraDoubleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
    // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;
    //     RecordError(-2000, info);
    // }

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1200, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }

        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraDoubleMB>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<KataraDoubleMB>(this, false);
        EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1300, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }

        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraDoubleMB>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<KataraDoubleMB>(this, false);
        EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);

        return;
    }

    // Start of Confirmation TF SEcond MB
    // This will always cancel any pending orders
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1400, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }

        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraDoubleMB>(this, true, false);
        EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);

        return;
    }

    if (!mHasSetup)
    {
        // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        return;
    }

    // End of Confirmation TF Second MB
    if (EAHelper::CheckBrokeMBRangeEnd<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1500, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }

        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraDoubleMB>(this, false, false);
        EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);

        return;
    }

    // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
}

void KataraDoubleMB::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    // if (mInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     RecordError(-1100);
    //     mInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
    // }

    EAHelper::InvalidateSetup<KataraDoubleMB>(this, deletePendingOrder, error);
}

bool KataraDoubleMB::Confirmation()
{
    // if (mConfirmationMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;

    //     RecordError(-1800, info);
    //     mConfirmationMBsCreated = mConfirmationMBT.MBsCreated();
    // }
    bool hasConfirmation = false;
    int error = EAHelper::MostRecentMBZoneIsHolding<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber, hasConfirmation);
    if (error != Errors::NO_ERROR)
    {
        EAHelper::InvalidateSetup<KataraDoubleMB>(this, true, false);
        EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);

        return false;
    }

    return hasConfirmation;
}

void KataraDoubleMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<KataraDoubleMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingMBValidation<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
    }
}

void KataraDoubleMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

void KataraDoubleMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

bool KataraDoubleMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<KataraDoubleMB>(this, ticket);
}

void KataraDoubleMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<KataraDoubleMB>(this, ticketIndex);
}

void KataraDoubleMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<KataraDoubleMB>(this);
}

void KataraDoubleMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<KataraDoubleMB>(this, ticketIndex);
}

void KataraDoubleMB::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<KataraDoubleMB>(this, 60);
}

void KataraDoubleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<KataraDoubleMB>(this, oldTicketIndex, newTicketNumber);
}

void KataraDoubleMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<KataraDoubleMB>(this, ticket, 1, 60);
}

void KataraDoubleMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<KataraDoubleMB>(this, error, additionalInformation);
}

void KataraDoubleMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}