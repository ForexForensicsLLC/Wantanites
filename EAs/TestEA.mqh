//+------------------------------------------------------------------+
//|                                                       TestEA.mqh |
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

class TestEA : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    int mSecondMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    int mTimeFrame;

public:
    TestEA(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
           CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst);
    ~TestEA();

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

TestEA::TestEA(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TestEA>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TestEA, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TestEA, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<TestEA>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<TestEA>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mTimeFrame = 1;
}

TestEA::~TestEA()
{
}

void TestEA::Run()
{
    EAHelper::RunDrawMBTs<TestEA>(this, mSetupMBT, mConfirmationMBT);
}

bool TestEA::AllowedToTrade()
{
    return EAHelper::BelowSpread<TestEA>(this);
}

void TestEA::CheckSetSetup()
{

    // if (EAHelper::CheckSetLiquidationMBSetup<TestEA>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    // {
    //     bool isTrue = false;
    //     int error = EAHelper::LiquidationMBZoneIsHolding<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, isTrue);
    //     if (error != ERR_NO_ERROR)
    //     {
    //         EAHelper::InvalidateSetup<TestEA>(this, true, false);
    //         EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
    //         EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);
    //     }
    //     else if (isTrue)
    //     {
    //         string additionalInformation = "";
    //         if (EAHelper::SetupZoneIsValidForConfirmation<TestEA>(this, mFirstMBInSetupNumber, 0, additionalInformation))
    //         {
    //             if (EAHelper::CheckSetSingleMBSetup<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
    //             {
    //                 mHasSetup = true;
    //             }
    //         }
    //     }
    // }

    if (EAHelper::CheckSetSingleMBSetup<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        bool isTrue = false;
        int error = EAHelper::MostRecentMBZoneIsHolding<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber, isTrue);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<TestEA>(this, true, false);
            EAHelper::ResetSingleMBSetup<TestEA>(this, false);
            EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        }
        else if (isTrue)
        {
            string additionalInformation = "";
            if (EAHelper::SetupZoneIsValidForConfirmation<TestEA>(this, mFirstMBInSetupNumber, 0, additionalInformation))
            {
                if (EAHelper::CheckSetSingleMBSetup<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void TestEA::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<TestEA>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeEnd<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<TestEA>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

        return;
    }

    // Start of Confirmation TF First MB
    // This will always cancel any pending orders
    if (EAHelper::CheckBrokeMBRangeStart<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<TestEA>(this, true, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

        return;
    }

    if (!mHasSetup)
    {

        return;
    }

    // End of Confirmation TF First MB
    // if (EAHelper::CheckBrokeMBRangeEnd<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber))
    // {
    //     // don't cancel any pending orders since the setup held and continued
    //     EAHelper::InvalidateSetup<TestEA>(this, false, false);
    //     EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

    //     return;
    // }
}

void TestEA::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    // RecordError(-22);

    EAHelper::InvalidateSetup<TestEA>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool TestEA::Confirmation()
{
    int currentBars = iBars(Symbol(), 1);

    MBState *setupMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, setupMBState))
    {
        return false;
    }

    if (!setupMBState.ClosestValidZoneIsHolding(setupMBState.EndIndex() + 1))
    {
        return false;
    }

    if (currentBars > mBarCount && mCurrentSetupTicket.Number() == EMPTY)
    {
        MBState *mostRecentConfirmationMB;
        if (!mConfirmationMBT.GetNthMostRecentMB(0, mostRecentConfirmationMB))
        {
            RecordError(-301);
            return false;
        }

        MBState *furthestMB;
        if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, furthestMB))
        {
            RecordError(-302);
            return false;
        }

        if (mostRecentConfirmationMB.Number() <= furthestMB.Number() + 2)
        {
            return false;
        }

        ZoneState *tempZoneState;
        if (!furthestMB.GetClosestValidZone(tempZoneState))
        {
            return false;
        }

        if (!tempZoneState.IsHolding(mostRecentConfirmationMB.EndIndex() + 1))
        {
            return false;
        }

        if (mSetupType == OP_BUY)
        {
            int lowIndex = 0.0;
            if (!MQLHelper::GetLowest(Symbol(), 1, MODE_LOW, tempZoneState.StartIndex() - tempZoneState.EntryOffset(), 0, false, lowIndex))
            {
                // RecordError(-1);
                return false;
            }

            if (lowIndex != 1)
            {
                string additionalInformation = "Low Index: " + lowIndex;
                // RecordError(-2, additionalInformation);
                return false;
            }

            if (iLow(Symbol(), 1, 1) > tempZoneState.EntryPrice())
            {
                // RecordError(-3);
                return false;
            }

            if (iLow(Symbol(), 1, 0) < iLow(Symbol(), 1, 1))
            {
                // RecordError(-4);
                return false;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            int highIndex = 0.0;
            if (!MQLHelper::GetHighest(Symbol(), 1, MODE_LOW, tempZoneState.StartIndex() - tempZoneState.EntryOffset(), 0, false, highIndex))
            {
                return false;
            }

            if (highIndex != 1)
            {
                return false;
            }

            if (iHigh(Symbol(), 1, 1) < tempZoneState.EntryPrice())
            {
                return false;
            }

            if (iHigh(Symbol(), 1, 0) > iHigh(Symbol(), 1, 1))
            {
                return false;
            }
        }

        double bodyLength = MathMax(iOpen(Symbol(), 1, 1), iClose(Symbol(), 1, 1)) - MathMin(iOpen(Symbol(), 1, 1), iClose(Symbol(), 1, 1));
        double totalLength = iHigh(Symbol(), 1, 1) - iLow(Symbol(), 1, 1);

        if (bodyLength / totalLength > 0.5)
        {
            // RecordError(-5);
            return false;
        }

        return true;
    }

    return mCurrentSetupTicket.Number() != EMPTY;

    // // need at least 2 mbs to print before tapping intot the zone. Add one so that the end index can count as tapping in
    // return mostRecentConfirmationMB.Number() >= furthestMB.Number() + 2 && furthestMB.ClosestValidZoneIsHolding(mostRecentConfirmationMB.EndIndex() + 1);

    // return mCurrentSetupTicket.Number() != EMPTY || (mFirstMBInConfirmationNumber != EMPTY &&
    //                                                  ((mConfirmationMBT.HasPendingBullishMB() && mSetupType == OP_BUY) ||
    //                                                   (mConfirmationMBT.HasPendingBearishMB() && mSetupType == OP_SELL)));
    // bool hasConfirmation = false;
    // if (currentBars > mBarCount)
    // {
    //     int error = EAHelper::EngulfingCandleInZone<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, hasConfirmation);
    //     if (error != ERR_NO_ERROR)
    //     {
    //         EAHelper::InvalidateSetup<TestEA>(this, true, false);
    //         EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

    //         return false;
    //     }

    //     mBarCount = currentBars;
    // }

    // return hasConfirmation || mCurrentSetupTicket.Number() != EMPTY;
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

void TestEA::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<TestEA>(this))
    {
        // MBState *mostRecentConfirmationMB;
        // if (!mConfirmationMBT.GetNthMostRecentMB(0, mostRecentConfirmationMB))
        // {
        //     RecordError(-303);
        //     return;
        // }

        // // EAHelper::PlaceStopOrderForPendingMBValidation<TestEA>(this, mConfirmationMBT, mostRecentConfirmationMB.Number());
        // MBState *tempMBState;
        // if (!mConfirmationMBT.GetNthMostRecentMB(0, tempMBState))
        // {
        //     EAHelper::InvalidateSetup<TestEA>(this, true, false, -55);
        //     EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);
        // }

        // if (mSetupType == tempMBState.Type())
        // {
        //     EAHelper::PlaceStopOrderForPendingMBValidation<TestEA>(this, mConfirmationMBT, tempMBState.Number());
        // }
        // else if (mSetupType != tempMBState.Type())
        // {
        //     EAHelper::PlaceStopOrderForBreakOfMB<TestEA>(this, mConfirmationMBT, tempMBState.Number());
        // }

        if (mSetupType == OP_BUY)
        {
            double entry = iHigh(Symbol(), 1, 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
            double stopLoss = iLow(Symbol(), 1, 0) - OrderHelper::PipsToRange(mStopLossPaddingPips);

            GetLastError();
            int ticket = OrderSend(Symbol(), OP_BUYSTOP, 0.1, entry, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
            EAHelper::PostPlaceOrderChecks<TestEA>(this, ticket, GetLastError());
        }
        else if (mSetupType == OP_SELL)
        {
            double entry = iLow(Symbol(), 1, 1);
            double stopLoss = iHigh(Symbol(), 1, 0) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips);

            GetLastError();
            int ticket = OrderSend(Symbol(), OP_SELLSTOP, 0.1, entry, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
            EAHelper::PostPlaceOrderChecks<TestEA>(this, ticket, GetLastError());
        }

        RecordError(-600);

        mEntryCandleTime = iTime(Symbol(), 1, 1);
    }
}

void TestEA::ManageCurrentPendingSetupTicket()
{
    // MBState *tempMBState;
    // if (!mConfirmationMBT.GetNthMostRecentMB(0, tempMBState))
    // {
    //     RecordError(-303);
    //     return;
    // }

    // if (mSetupType == tempMBState.Type())
    // {
    //     EAHelper::CheckEditStopLossForPendingMBValidation<TestEA>(this, mConfirmationMBT, tempMBState.Number());
    // }
    // else if (mSetupType != tempMBState.Type())
    // {
    //     EAHelper::CheckEditStopLossForBreakOfMB<TestEA>(this, mConfirmationMBT, tempMBState.Number());
    // }

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    bool isActive = false;
    int error = mCurrentSetupTicket.IsActive(isActive);
    if (error == TerminalErrors::ORDER_IS_CLOSED)
    {
        InvalidateSetup(true, error);
        mCurrentSetupTicket.SetNewTicket(EMPTY);

        return;
    }

    if (isActive)
    {
        return;
    }

    if (!OrderSelect(mCurrentSetupTicket.Number(), SELECT_BY_TICKET))
    {
        RecordError(-500);
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(Symbol(), Period(), 0) < iLow(Symbol(), Period(), 1))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
            return;
        }

        if (iLow(Symbol(), Period(), 0) < OrderStopLoss())
        {
            double newStopLoss = iLow(Symbol(), Period(), 0) - OrderHelper::PipsToRange(mStopLossPaddingPips);
            OrderModify(mCurrentSetupTicket.Number(), OrderOpenPrice(), newStopLoss, 0, 0, clrNONE);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(Symbol(), Period(), 0) > iHigh(Symbol(), Period(), 1))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
            return;
        }

        if (iHigh(Symbol(), Period(), 0) > OrderStopLoss())
        {
            double newStopLoss = iHigh(Symbol(), Period(), 0) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
            OrderModify(mCurrentSetupTicket.Number(), OrderOpenPrice(), newStopLoss, 0, 0, clrNONE);
            return;
        }
    }
}

void TestEA::ManageCurrentActiveSetupTicket()
{
    MBState *tempMBState;
    if (!mConfirmationMBT.GetNthMostRecentMB(0, tempMBState))
    {
        RecordError(-303);
        return;
    }

    EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<TestEA>(this);
}

bool TestEA::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // bool isActive = false;
    // int error = mCurrentSetupTicket.IsActive(isActive);

    // return isActive;
    // return EAHelper::TicketStopLossIsMovedToBreakEven<TestEA>(this, ticket);
    return false;
}

void TestEA::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TestEA>(this, ticketIndex);
}

void TestEA::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<TestEA>(this);
}

void TestEA::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<TestEA>(this, ticketIndex);
}

void TestEA::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<TestEA>(this, 60);
}

void TestEA::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TestEA>(this, oldTicketIndex, newTicketNumber);
}

void TestEA::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<TestEA>(this, ticket, 1, 60);
}

void TestEA::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TestEA>(this, error, additionalInformation);
}

void TestEA::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}