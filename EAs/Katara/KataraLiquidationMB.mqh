//+------------------------------------------------------------------+
//|                                   KataraLiquidationMB.mqh |
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

class KataraLiquidationMB : public EA
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;
    int mLiquidationMBInConfirmationNumber;

public:
    KataraLiquidationMB(string directory, int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        MBTracker *&setupMBT, MBTracker *&confirmationMBT);
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
    virtual void RecordTicketCloseData();
    virtual void RecordError(int error);
    virtual void Reset();
};

KataraLiquidationMB::KataraLiquidationMB(string directory, int setupType, int maxTradesPerStrategy, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         MBTracker *&setupMBT, MBTracker *&confirmationMBT) : EA(directory, maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;
    mLiquidationMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<KataraLiquidationMB>(this);
    mTradeRecordRecorder.SearchSetRRAcquired<SinglePartialMultiTimeFrameTradeRecord>(mPreviousSetupTickets);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<KataraLiquidationMB>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<KataraLiquidationMB>(this);
    }
}

KataraLiquidationMB::~KataraLiquidationMB()
{
    delete mSetupMBT;
    delete mConfirmationMBT;
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
    if (EAHelper::CheckSetLiquidationMBAfterBreak<KataraLiquidationMB>(this, mSetupMBT,
                                                                       mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber, mSetupType))
    {
        if (EAHelper::LiquidationMBZoneIsHolding<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber))
        {
            if (EAHelper::MBRetappedDeepestHoldingSetupZone<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT) ||
                EAHelper::MBPushedFurtherIntoDeepestHoldingSetupZone<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT))
            {
                if (EAHelper::CheckSetLiquidationMBAfterBreak<KataraLiquidationMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber,
                                                                                   mSecondMBInConfirmationNumber, mLiquidationMBInConfirmationNumber, mSetupType))
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

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber, false))
    {
        return;
    }

    // Start of Confirmation TF First MB
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    // End of Confirmation TF Liqudiation MB
    if (EAHelper::CheckBrokeMBRangeStart<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInSetupNumber, false))
    {
        return;
    }
}

void KataraLiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<KataraLiquidationMB>(this, deletePendingOrder, error);

    EAHelper::ResetLiquidationMBSetup<KataraLiquidationMB>(this, false);
    EAHelper::ResetLiquidationMBConfirmation<KataraLiquidationMB>(this, false);
}

bool KataraLiquidationMB::Confirmation()
{
    return EAHelper::LiquidationMBZoneIsHolding<KataraLiquidationMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSecondMBInConfirmationNumber);
}

void KataraLiquidationMB::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<KataraLiquidationMB>(this))
    {
        EAHelper::PlaceStopOrderForBreakOfMB<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber);
    }
}

void KataraLiquidationMB::ManageCurrentPendingSetupTicket()
{
    EAHelper::CheckEditStopLossForBreakOfMB<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber);
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
    EAHelper::RecordSinglePartialMultiTimeFrameTicketOpenData<KataraLiquidationMB>(this, 1, 60);
}

void KataraLiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordSinglePartialMultiTimeFrameTicketPartialData<KataraLiquidationMB>(this, oldTicketIndex, newTicketNumber);
}

void KataraLiquidationMB::RecordTicketCloseData()
{
    EAHelper::RecordSinglePartialMultiTimeFrameTicketCloseData<KataraLiquidationMB>(this, 1, 60);
}

void KataraLiquidationMB::RecordError(int error)
{
    EAHelper::RecordDefaultErrorRecord<KataraLiquidationMB>(this, error);
}

void KataraLiquidationMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}