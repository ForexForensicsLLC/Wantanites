//+------------------------------------------------------------------+
//|                                                    CrossAlligatorLips.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class CrossAlligatorLips : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    double mMaxPipsFromGreenLips;
    double mMinBlueRedAlligatorGap;
    double mMinRedGreenAlligatorGap;

    double mMinWickLength;

public:
    CrossAlligatorLips(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~CrossAlligatorLips();

    double BlueJaw(int index);
    double RedTeeth(int index);
    double GreenLips(int index);

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void PreRun();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void PreManageTickets();
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket);
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket);
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(Ticket &ticket);
    virtual void CheckCurrentSetupTicket(Ticket &ticket);
    virtual void CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};
CrossAlligatorLips::CrossAlligatorLips(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter,
         exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mMaxPipsFromGreenLips = 0.0;
    mMinBlueRedAlligatorGap = 0.0;
    mMinRedGreenAlligatorGap = 0.0;
    mMinWickLength = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<CrossAlligatorLips>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<CrossAlligatorLips, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<CrossAlligatorLips, SingleTimeFrameEntryTradeRecord>(this);
}

CrossAlligatorLips::~CrossAlligatorLips()
{
}

double CrossAlligatorLips::BlueJaw(int index)
{
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, index);
}
double CrossAlligatorLips::RedTeeth(int index)
{
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, index);
}
double CrossAlligatorLips::GreenLips(int index)
{
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, index);
}

void CrossAlligatorLips::PreRun()
{
}

bool CrossAlligatorLips::AllowedToTrade()
{
    return EAHelper::BelowSpread<CrossAlligatorLips>(this) && EAHelper::WithinTradingSession<CrossAlligatorLips>(this);
}

void CrossAlligatorLips::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    double redGreenGap = MathAbs(GreenLips(0) - RedTeeth(0));
    if (redGreenGap < mMinRedGreenAlligatorGap)
    {
        return;
    }

    double redBlueGap = MathAbs(RedTeeth(0) - BlueJaw(0));
    if (redBlueGap < mMinBlueRedAlligatorGap)
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        if (GreenLips(0) > RedTeeth(0) && RedTeeth(0) > BlueJaw(0))
        {
            mHasSetup = true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (GreenLips(0) < RedTeeth(0) && RedTeeth(0) < BlueJaw(0))
        {
            mHasSetup = true;
        }
    }
}

void CrossAlligatorLips::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (!mHasSetup)
    {
        return;
    }

    double redGreenGap = MathAbs(GreenLips(0) - RedTeeth(0));
    if (redGreenGap < mMinRedGreenAlligatorGap)
    {
        InvalidateSetup(false);
    }

    double redBlueGap = MathAbs(RedTeeth(0) - BlueJaw(0));
    if (redBlueGap < mMinBlueRedAlligatorGap)
    {
        InvalidateSetup(false);
    }
}

void CrossAlligatorLips::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<CrossAlligatorLips>(this, deletePendingOrder, false, error);
}

bool CrossAlligatorLips::Confirmation()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return false;
    }

    if (SetupType() == OP_BUY)
    {
        return iClose(mEntrySymbol, mEntryTimeFrame, 2) > GreenLips(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) < GreenLips(1);
    }
    else if (SetupType() == OP_SELL)
    {
        return iClose(mEntrySymbol, mEntryTimeFrame, 2) < GreenLips(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) > GreenLips(1);
    }

    return false;
}

void CrossAlligatorLips::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceMarketOrder<CrossAlligatorLips>(this, entry, stopLoss);
}

void CrossAlligatorLips::PreManageTickets()
{
}

void CrossAlligatorLips::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void CrossAlligatorLips::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, ticket.OpenTime());
    if (entryIndex >= 2)
    {
        if (SetupType() == OP_BUY && iClose(mEntrySymbol, mEntryTimeFrame, 1) > ticket.OpenPrice())
        {
            EAHelper::MoveTicketToBreakEven<CrossAlligatorLips>(this, ticket);
            return;
        }
        else if (SetupType() == OP_SELL && iClose(mEntrySymbol, mEntryTimeFrame, 1) < ticket.OpenPrice())
        {
            EAHelper::MoveTicketToBreakEven<CrossAlligatorLips>(this, ticket);
            return;
        }
    }

    EAHelper::CheckPartialTicket<CrossAlligatorLips>(this, ticket);
}

bool CrossAlligatorLips::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CrossAlligatorLips>(this, ticket);
}

void CrossAlligatorLips::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<CrossAlligatorLips>(this, ticket);
}

void CrossAlligatorLips::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void CrossAlligatorLips::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void CrossAlligatorLips::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<CrossAlligatorLips>(this, ticket);
}

void CrossAlligatorLips::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<CrossAlligatorLips>(this, partialedTicket, newTicketNumber);
}

void CrossAlligatorLips::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<CrossAlligatorLips>(this, ticket, Period());
}

void CrossAlligatorLips::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<CrossAlligatorLips>(this, error, additionalInformation);
}

bool CrossAlligatorLips::ShouldReset()
{
    return !EAHelper::WithinTradingSession<CrossAlligatorLips>(this);
}

void CrossAlligatorLips::Reset()
{
    InvalidateSetup(false);
}
