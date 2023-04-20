//+------------------------------------------------------------------+
//|                                                    MultiTimeFrameMBs.mqh |
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

class MultiTimeFrameMBs : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;
    int mFirstMBInEntryNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;

    int mSetupBarCount;
    int mEntryBarCount;

    string mSetupSymbol;
    int mSetupTimeFrame;

    string mEntrySymbol;
    int mEntryTimeFrame;

    datetime mFailedImpulseEntryTime;
    bool mClosedOutsideEntry;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MultiTimeFrameMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                      CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                      CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT);
    ~MultiTimeFrameMBs();

    virtual double RiskPercent();

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
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

MultiTimeFrameMBs::MultiTimeFrameMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                     CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mEntryMBT = entryMBT;

    mFirstMBInSetupNumber = EMPTY;
    mFirstMBInEntryNumber = EMPTY;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MultiTimeFrameMBs>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MultiTimeFrameMBs, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MultiTimeFrameMBs, MultiTimeFrameEntryTradeRecord>(this);

    mSetupBarCount = 0;
    mEntryBarCount = 0;

    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;
    mClosedOutsideEntry = false;

    mSetupSymbol = Symbol();
    mSetupTimeFrame = Period();

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

MultiTimeFrameMBs::~MultiTimeFrameMBs()
{
}

double MultiTimeFrameMBs::RiskPercent()
{
    return mRiskPercent;
}

void MultiTimeFrameMBs::Run()
{
    EAHelper::RunDrawMBTs<MultiTimeFrameMBs>(this, mSetupMBT, mEntryMBT);

    mSetupBarCount = iBars(mSetupSymbol, mSetupTimeFrame);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MultiTimeFrameMBs::AllowedToTrade()
{
    return EAHelper::BelowSpread<MultiTimeFrameMBs>(this) && EAHelper::WithinTradingSession<MultiTimeFrameMBs>(this);
}

void MultiTimeFrameMBs::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<MultiTimeFrameMBs>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (EAHelper::MostRecentMBZoneIsHolding<MultiTimeFrameMBs>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            if (EAHelper::CheckSetSingleMBSetup<MultiTimeFrameMBs>(this, mEntryMBT, mFirstMBInEntryNumber, mSetupType))
            {
                mHasSetup = true;
            }
        }
    }
}

void MultiTimeFrameMBs::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mSetupSymbol, mSetupTimeFrame) > mSetupBarCount)
    {
        if (mFirstMBInSetupNumber != EMPTY)
        {
            if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
            {
                InvalidateSetup(true);
                mFirstMBInEntryNumber = EMPTY;
                mFirstMBInSetupNumber = EMPTY;

                return;
            }
        }
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) > mEntryBarCount)
    {
        if (mFirstMBInEntryNumber != EMPTY)
        {
            if (mFirstMBInEntryNumber != mEntryMBT.MBsCreated() - 1)
            {
                InvalidateSetup(true);
                mFirstMBInEntryNumber = EMPTY;
            }
        }
    }
}

void MultiTimeFrameMBs::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<MultiTimeFrameMBs>(this, deletePendingOrder, false, error);
}

bool MultiTimeFrameMBs::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return false;
    }

    bool furthestCandleInZone = EAHelper::CandleIsInZone<MultiTimeFrameMBs>(this, mEntryMBT, mFirstMBInEntryNumber, 1, true);
    if (!furthestCandleInZone)
    {
        return false;
    }

    bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<MultiTimeFrameMBs>(this, mEntryMBT, mFirstMBInEntryNumber, 1);
    if (!dojiInZone)
    {
        return false;
    }

    return true;
}

void MultiTimeFrameMBs::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips);
    }

    EAHelper::PlaceStopOrder<MultiTimeFrameMBs>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInEntryNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
        mClosedOutsideEntry = false;
    }
}

void MultiTimeFrameMBs::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    // if (entryCandleIndex > 1)
    // {
    //     InvalidateSetup(true);
    // }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void MultiTimeFrameMBs::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    bool movedPips = false;
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }

        //     // close if we put in a bearish candle
        //     if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double lowest = 0.0;
        //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // close if we pushed 20% into our SL
        // double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // // TODO: instead of doing this, just BE
        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double highestBody = 0.0;
        //     if (!MQLHelper::GetHighestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, highestBody))
        //     {
        //         return;
        //     }

        //     if (highestBody > OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.bid <= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     // close if we put in a bullish candle
        //     if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double highest = 0.0;
        //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // close if we push 20% into our SL
        // double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double lowestBody = 0.0;
        //     if (!MQLHelper::GetLowestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, lowestBody))
        //     {
        //         return;
        //     }

        //     if (lowestBody < OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.ask >= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // BE after we validate the MB we entered in
    // if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<MultiTimeFrameMBs>(this, mBEAdditionalPips);
    // }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MultiTimeFrameMBs>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<MultiTimeFrameMBs>(this, mCurrentSetupTicket);
}

bool MultiTimeFrameMBs::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MultiTimeFrameMBs>(this, ticket);
}

void MultiTimeFrameMBs::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MultiTimeFrameMBs>(this, mPreviousSetupTickets[ticketIndex]);
}

void MultiTimeFrameMBs::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MultiTimeFrameMBs>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MultiTimeFrameMBs>(this);
}

void MultiTimeFrameMBs::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MultiTimeFrameMBs>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MultiTimeFrameMBs>(this, ticketIndex);
}

void MultiTimeFrameMBs::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MultiTimeFrameMBs>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void MultiTimeFrameMBs::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MultiTimeFrameMBs>(this, partialedTicket, newTicketNumber);
}

void MultiTimeFrameMBs::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MultiTimeFrameMBs>(this, ticket, Period());
}

void MultiTimeFrameMBs::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MultiTimeFrameMBs>(this, error, additionalInformation);
}

void MultiTimeFrameMBs::Reset()
{
}