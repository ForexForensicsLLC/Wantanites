//+------------------------------------------------------------------+
//|                                        KataraSingleMB.mqh |
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

class KataraSingleMB : public EA<MultiTimeFrameTradeRecord>
{
public:
    Ticket *mTicket;
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;

    int mSetupType;

public:
    KataraSingleMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
                   MBTracker *&confirmationMBT);
    ~KataraSingleMB();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }

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

KataraSingleMB::KataraSingleMB(int setupType, int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT,
                               MBTracker *&confirmationMBT) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    string prefix = mSetupType == OP_BUY ? "Bullish" : "Bearish";
    mDirectory = "/Katara/" + prefix + "/SingleMB/";
    mCSVFileName = prefix + "KataraSingleMB.csv";

    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mTicket = new Ticket();

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;

    mSetupType = setupType;

    EAHelper::FillBearishKataraMagicNumbers<KataraSingleMB>(this);
    EAHelper::SetSingleActiveTicket<KataraSingleMB>(this);
}

KataraSingleMB::~KataraSingleMB()
{
    delete mSetupMBT;
    delete mConfirmationMBT;
    delete mTicket;
}

void KataraSingleMB::Run()
{
    EAHelper::RunDrawMBT<KataraSingleMB>(this, mConfirmationMBT);
}

bool KataraSingleMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<KataraSingleMB>(this);
}

void KataraSingleMB::CheckSetSetup()
{
    if (EAHelper::CheckSetLiquidationMBAfterBreak<KataraSingleMB>(this, mSetupMBT,
                                                                  mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber, mSetupType))
    {
        if (EAHelper::LiquidationMBZoneIsHolding<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber))
        {
            if (EAHelper::MBRetappedSetupZone<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT) ||
                EAHelper::MBPushedFurtherIntoSetupZone<KataraSingleMB>(this, mSetupMBT, mFirstMBInSetupNumber, mConfirmationMBT))
            {
                if (EAHelper::CheckSetFirstMBAfterBreak<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
                {
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
    EAHelper::InvalidateSetup<KataraSingleMB>(this, deletePendingOrder, error);

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

void KataraSingleMB::ManagePendingTicket()
{
    EAHelper::CheckEditStopLossForPendingMBValidation<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

void KataraSingleMB::ManageActiveTicket()
{
    EAHelper::CheckTrailStopLossWithMBs<KataraSingleMB>(this, mConfirmationMBT, mFirstMBInConfirmationNumber);
}

void KataraSingleMB::CheckTicket()
{
    EAHelper::CheckTicket<KataraSingleMB>(this);
}

void KataraSingleMB::RecordOrderOpenData()
{
    EAHelper::RecordMultiTimeFrameRecordOpenData<KataraSingleMB>(this, 1, 60);
}

void KataraSingleMB::RecordOrderCloseData()
{
    EAHelper::RecordMultiTimeFrameRecordCloseData<KataraSingleMB>(this, 1, 60);
}

void KataraSingleMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do much
}