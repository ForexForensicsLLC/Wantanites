//+------------------------------------------------------------------+
//|                                        KataraDoubleMB.mqh |
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

class KataraDoubleMB : public EA
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;

public:
    KataraDoubleMB(string directory, int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
                   MBTracker *&confirmationMBT);
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
    virtual void RecordTicketCloseData();
    virtual void RecordError(int error);
    virtual void Reset();
};

KataraDoubleMB::KataraDoubleMB(string directory, int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               MBTracker *&setupMBT, MBTracker *&confirmationMBT) : EA(directory, maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraDoubleMB>(this);
    mTradeRecordRecorder.SearchSetRRAcquired<SinglePartialMultiTimeFrameTradeRecord>(mPreviousSetupTickets);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraDoubleMB>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraDoubleMB>(this);
    }
}

KataraDoubleMB::~KataraDoubleMB()
{
    delete mSetupMBT;
    delete mConfirmationMBT;
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
    if (EAHelper::CheckSetLiquidationMBAfterBreak<KataraDoubleMB>(this, mSetupMBT,
                                                                  mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber, mSetupType))
    {
        if (EAHelper::LiquidationMBZoneIsHolding<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber))
        {
            if (EAHelper::MBRetappedDeepestHoldingSetupZone<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT) ||
                EAHelper::MBPushedFurtherIntoDeepestHoldingSetupZone<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT))
            {
                if (EAHelper::CheckSetSecondMBAfterBreak<KataraDoubleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber,
                                                                         mSecondMBInConfirmationNumber, mSetupType))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void KataraDoubleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mSetupMBT, mLiquidationMBInSetupNumber, false))
    {
        return;
    }

    // Start of Confirmation TF SEcond MB
    if (EAHelper::CheckBrokeMBRangeStart<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    // End of Confirmation TF Second MB
    if (EAHelper::CheckBrokeMBRangeEnd<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber))
    {
        return;
    }
}

void KataraDoubleMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<KataraDoubleMB>(this, deletePendingOrder, error);

    EAHelper::ResetLiquidationMBSetup<KataraDoubleMB>(this, false);
    EAHelper::ResetDoubleMBConfirmation<KataraDoubleMB>(this, false);
}

bool KataraDoubleMB::Confirmation()
{
    return EAHelper::MostRecentMBZoneIsHolding<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
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

void KataraDoubleMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordSinglePartialMultiTimeFrameTicketPartialData<KataraDoubleMB>(this, oldTicketIndex, newTicketNumber);
}

void KataraDoubleMB::RecordTicketCloseData()
{
    EAHelper::RecordSinglePartialMultiTimeFrameTicketCloseData<KataraDoubleMB>(this, 1, 60);
}

void KataraDoubleMB::RecordError(int error)
{
    EAHelper::RecordDefaultErrorRecord<KataraDoubleMB>(this, error);
}

void KataraDoubleMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}