//+------------------------------------------------------------------+
//|                                        KataraDoubleMB.mqh |
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

class KataraDoubleMB : public EA<MultiTimeFrameTradeRecord>
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

    int mSetupType;

public:
    KataraDoubleMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
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
    virtual void ManagePendingTicket();
    virtual void ManageActiveTicket();
    virtual void CheckTicket();
    virtual void RecordOrderOpenData();
    virtual void RecordOrderCloseData();
    virtual void Reset();
};

KataraDoubleMB::KataraDoubleMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
                               MBTracker *&confirmationMBT) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    string prefix = mSetupType == OP_BUY ? "Bullish" : "Bearish";
    mDirectory = "/Katara/" + prefix + "/DoubleMB/";
    mCSVFileName = prefix + "KataraDoubleMB.csv";

    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mTicket = new Ticket();

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FillBearishKataraMagicNumbers<KataraDoubleMB>(this);
    EAHelper::SetSingleActiveTicket<KataraDoubleMB>(this);
}

KataraDoubleMB::~KataraDoubleMB()
{
    delete mSetupMBT;
    delete mConfirmationMBT;
    delete mTicket;
}

void KataraDoubleMB::Run()
{
    EAHelper::RunDrawMBT<KataraDoubleMB>(this, mConfirmationMBT);
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
            if (EAHelper::MBRetappedSetupZone<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT) ||
                EAHelper::MBPushedFurtherIntoSetupZone<KataraDoubleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT))
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

void KataraDoubleMB::ManagePendingTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

void KataraDoubleMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraDoubleMB>(this, mConfirmationMBT, mSecondMBInConfirmationNumber);
}

void KataraDoubleMB::CheckTicket()
{
    EAHelper::CheckTicket<KataraDoubleMB>(this);
}

void KataraDoubleMB::RecordOrderOpenData()
{
    EAHelper::RecordMultiTimeFrameRecordOpenData<KataraDoubleMB>(this, 1, 60);
}

void KataraDoubleMB::RecordOrderCloseData()
{
    EAHelper::RecordMultiTimeFrameRecordCloseData<KataraDoubleMB>(this, 1, 60);
}

void KataraDoubleMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do much
}