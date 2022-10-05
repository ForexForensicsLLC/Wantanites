//+------------------------------------------------------------------+
//|                                                        Rango.mqh |
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

class Rango : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;

public:
    Rango(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
          CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
          CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~Rango();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishRango : MagicNumbers::BearishRango; }
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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

Rango::Rango(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<Rango>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<Rango, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<Rango, SingleTimeFrameEntryTradeRecord>(this);
}

Rango::~Rango()
{
}

double Rango::RiskPercent()
{
    double riskPercent = 0.25;
    double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;

    // for each one percent that we lost, reduce risk by 0.05 %
    while (percentLost >= 1)
    {
        riskPercent -= 0.05;
        percentLost -= 1;
    }

    return riskPercent;
}

void Rango::Run()
{
    EAHelper::RunDrawMBT<Rango>(this, mSetupMBT);
}

bool Rango::AllowedToTrade()
{
    return EAHelper::BelowSpread<Rango>(this) && (Hour() >= 17 && Hour() < 23);
}

void Rango::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<Rango>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void Rango::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mHasSetup = false;
        mFirstMBInSetupNumber = EMPTY;
    }
}

void Rango::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<Rango>(this, deletePendingOrder, false, error);
}

bool Rango::Confirmation()
{
    int entryCandle = 0;

    bool hasConfirmation = false;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<Rango>(this, mSetupMBT, mFirstMBInSetupNumber, hasConfirmation, entryCandle);
    if (error != ERR_NO_ERROR)
    {
        return false;
    }

    return hasConfirmation;
}

void Rango::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double stopLossPips = 30;

    if (mSetupType == OP_BUY)
    {
        entry = Ask;
        stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = Bid;
        stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);
    }

    EAHelper::PlaceMarketOrder<Rango>(this, entry, stopLoss);
    mBarCount = currentBars;
}

void Rango::ManageCurrentPendingSetupTicket()
{
    // we are placing market orders so we won't ever have pending orders
}

void Rango::ManageCurrentActiveSetupTicket()
{
    EAHelper::MoveToBreakEvenAsSoonAsPossible<Rango>(this);
}

bool Rango::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<Rango>(this, ticket);
}

void Rango::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Rango>(this, ticketIndex);
}

void Rango::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Rango>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<Rango>(this);
}

void Rango::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Rango>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<Rango>(this, ticketIndex);
}

void Rango::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<Rango>(this);
}

void Rango::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Rango>(this, oldTicketIndex, newTicketNumber);
}

void Rango::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Rango>(this, ticket, Period());
}

void Rango::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Rango>(this, error, additionalInformation);
}

void Rango::Reset()
{
}
