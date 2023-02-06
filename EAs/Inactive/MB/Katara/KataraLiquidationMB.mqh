//+------------------------------------------------------------------+
//|                                   KataraLiquidationMB.mqh |
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

class KataraLiquidationMB : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    LiquidationSetupTracker *mSetupLST;
    LiquidationSetupTracker *mConfirmationLST;

    int mLastCheckedSetupMB;
    int mLastCheckedConfirmationMB;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;
    int mLiquidationMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

public:
    KataraLiquidationMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&setupLST,
                        LiquidationSetupTracker *&confirmationLST);
    ~KataraLiquidationMB();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraLiquidationMB : MagicNumbers::BearishKataraLiquidationMB; }

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

KataraLiquidationMB::KataraLiquidationMB(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT,
                                         LiquidationSetupTracker *&setupLST, LiquidationSetupTracker *&confirmationLST)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mSetupLST = setupLST;
    mConfirmationLST = confirmationLST;

    mSetupType = setupType;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;
    mLiquidationMBInConfirmationNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraLiquidationMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<KataraLiquidationMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<KataraLiquidationMB, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraLiquidationMB>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraLiquidationMB>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;
}

KataraLiquidationMB::~KataraLiquidationMB()
{
}

void KataraLiquidationMB::Run()
{
    EAHelper::RunDrawMBTs<KataraLiquidationMB>(this, mSetupMBT, mConfirmationMBT);
}

bool KataraLiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<KataraLiquidationMB>(this);
}

void KataraLiquidationMB::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBSetup<KataraLiquidationMB>(this, mSetupLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        bool isTrue = false;
        int error = EAHelper::LiquidationMBZoneIsHolding<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, isTrue);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<KataraLiquidationMB>(this, true, false);
            EAHelper::ResetLiquidationMBSetup<KataraLiquidationMB>(this, false);
            EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);
        }
        else if (isTrue)
        {
            string additionalInformation = "";
            if (EAHelper::SetupZoneIsValidForConfirmation<KataraLiquidationMB>(this, mFirstMBInSetupNumber, 2, additionalInformation))
            {
                if (EAHelper::CheckSetLiquidationMBSetup<KataraLiquidationMB>(this, mConfirmationLST, mFirstMBInConfirmationNumber, mSecondMBInConfirmationNumber,
                                                                              mLiquidationMBInConfirmationNumber))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void KataraLiquidationMB::CheckInvalidateSetup()
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
    //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;
    //     RecordError(-2000, info);
    // }

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1200, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraLiquidationMB>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<KataraLiquidationMB>(this, false);
        EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1300, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraLiquidationMB>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<KataraLiquidationMB>(this, false);
        EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);

        return;
    }

    // Start of Confirmation TF First MB
    // This will always cancel any pending orders
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1400, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<KataraLiquidationMB>(this, true, false);
        EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);

        return;
    }

    if (!mHasSetup)
    {
        // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();

        return;
    }

    // End of Confirmation TF Liqudiation MB
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber))
    {
        // if (mCheckInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
        // {
        //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
        //                   " First MB In setup: " + mFirstMBInSetupNumber +
        //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
        //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
        //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
        //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
        //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
        //                   " Has Setup: " + mHasSetup;
        //     RecordError(-1500, info);

        //     mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
        // }
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<KataraLiquidationMB>(this, false, false);
        EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);

        return;
    }

    // mCheckInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
}

void KataraLiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    // if (mInvalidateSetupMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     RecordError(-1100);
    //     mInvalidateSetupMBsCreated = mConfirmationMBT.MBsCreated();
    // }

    EAHelper::InvalidateSetup<KataraLiquidationMB>(this, deletePendingOrder, error);
}

bool KataraLiquidationMB::Confirmation()
{
    // if (mConfirmationMBsCreated < mConfirmationMBT.MBsCreated())
    // {
    //     string info = "Total MBs: " + mConfirmationMBT.MBsCreated() +
    //                   " First MB In setup: " + mFirstMBInSetupNumber +
    //                   " Second MB In Setup: " + mSecondMBInSetupNumber +
    //                   " Liquidation MB In Setup: " + mLiquidationMBInSetupNumber +
    //                   " First MB In Conf. " + mFirstMBInConfirmationNumber +
    //                   " Second MB in Conf. " + mSecondMBInConfirmationNumber +
    //                   " Liq. MB In Cof. " + mLiquidationMBInConfirmationNumber +
    //                   " Has Setup: " + mHasSetup;

    //     RecordError(-1800, info);
    //     mConfirmationMBsCreated = mConfirmationMBT.MBsCreated();
    // }
    bool hasConfirmation = false;
    int error = EAHelper::LiquidationMBZoneIsHolding<KataraLiquidationMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSecondMBInConfirmationNumber, hasConfirmation);
    if (error != ERR_NO_ERROR)
    {
        EAHelper::InvalidateSetup<KataraLiquidationMB>(this, true, false);
        EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);

        return false;
    }

    return hasConfirmation;
}

void KataraLiquidationMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<KataraLiquidationMB>(this))
    {
        EAHelper::PlaceStopOrderForPendingLiquidationSetupValidation<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber);
    }
}

void KataraLiquidationMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForLiquidationMBSetup<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber);
}

void KataraLiquidationMB::ManageCurrentActiveSetupTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraLiquidationMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

bool KataraLiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<KataraLiquidationMB>(this, ticket);
}

void KataraLiquidationMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<KataraLiquidationMB>(this, ticketIndex);
}

void KataraLiquidationMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<KataraLiquidationMB>(this);
}

void KataraLiquidationMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<KataraLiquidationMB>(this, ticketIndex);
}

void KataraLiquidationMB::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<KataraLiquidationMB>(this, 60);
}

void KataraLiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<KataraLiquidationMB>(this, oldTicketIndex, newTicketNumber);
}

void KataraLiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<KataraLiquidationMB>(this, ticket, 1, 60);
}

void KataraLiquidationMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<KataraLiquidationMB>(this, error, additionalInformation);
}

void KataraLiquidationMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}