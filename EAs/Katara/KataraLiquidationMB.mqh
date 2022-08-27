//+------------------------------------------------------------------+
//|                                   KataraLiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\MultiTimeFrameTradeRecord.mqh>
#include <SummitCapital\Framework\EA\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

class KataraLiquidationMB : public EA<MultiTimeFrameTradeRecord>
{
public:
    Ticket *mTicket;
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;
    int mLiquidationMBInConfirmationNumber;

    int mSetupType;

public:
    KataraLiquidationMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
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
    virtual void ManagePendingTicket();
    virtual void ManageActiveTicket();
    virtual void CheckTicket();
    virtual void RecordOrderOpenData();
    virtual void RecordOrderCloseData();
    virtual void Reset();
};

KataraLiquidationMB::KataraLiquidationMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
                                         MBTracker *&confirmationMBT) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    string prefix = mSetupType == OP_BUY ? "Bullish" : "Bearish";
    mDirectory = "/Katara/" + prefix + "/LiquidationMB/";
    mCSVFileName = prefix + "KataraLiquidationMB.csv";

    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mTicket = new Ticket();

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;
    mLiquidationMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FillBearishKataraMagicNumbers<KataraLiquidationMB>(this);
    EAHelper::SetSingleActiveTicket<KataraLiquidationMB>(this);
}

KataraLiquidationMB::~KataraLiquidationMB()
{
    delete mSetupMBT;
    delete mConfirmationMBT;
    delete mTicket;
}

void KataraLiquidationMB::Run()
{
    EAHelper::RunDrawMBT<KataraLiquidationMB>(this, mConfirmationMBT);
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
            if (EAHelper::MBRetappedSetupZone<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT) ||
                EAHelper::MBPushedFurtherIntoSetupZone<KataraLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT))
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

void KataraLiquidationMB::ManagePendingTicket()
{
    EAHelper::CheckEditStopLossForBreakOfMB<KataraLiquidationMB>(this, mConfirmationMBT, mLiquidationMBInConfirmationNumber);
}

void KataraLiquidationMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraLiquidationMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

void KataraLiquidationMB::CheckTicket()
{
    EAHelper::CheckTicket<KataraLiquidationMB>(this);
}

void KataraLiquidationMB::RecordOrderOpenData()
{
    EAHelper::RecordMultiTimeFrameRecordOpenData<KataraLiquidationMB>(this, 1, 60);
}

void KataraLiquidationMB::RecordOrderCloseData()
{
    EAHelper::RecordMultiTimeFrameRecordCloseData<KataraLiquidationMB>(this, 1, 60);
}

void KataraLiquidationMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do much
}