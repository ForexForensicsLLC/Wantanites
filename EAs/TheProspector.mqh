//+------------------------------------------------------------------+
//|                                                TheProspector.mqh |
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

class TheProspector : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;

public:
    TheProspector(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                  CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheProspector();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::TheBullishProspector : MagicNumbers::TheBearishProspector; }
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

TheProspector::TheProspector(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheProspector>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheProspector, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheProspector, SingleTimeFrameEntryTradeRecord>(this);
}

TheProspector::~TheProspector()
{
}

double TheProspector::RiskPercent()
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

void TheProspector::Run()
{
    EAHelper::RunDrawMBT<TheProspector>(this, mSetupMBT);
}

bool TheProspector::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheProspector>(this) && (Hour() >= 16 && Hour() <= 18);
}

void TheProspector::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<TheProspector>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void TheProspector::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mHasSetup = false;
        mFirstMBInSetupNumber = EMPTY;
    }
}

void TheProspector::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheProspector>(this, deletePendingOrder, false, error);
}

bool TheProspector::Confirmation()
{
    int entryCandle = 0;

    bool hasConfirmation = false;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<TheProspector>(this, mSetupMBT, mFirstMBInSetupNumber, hasConfirmation, entryCandle);
    if (error != ERR_NO_ERROR)
    {
        return false;
    }

    return hasConfirmation;
}

void TheProspector::PlaceOrders()
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
    double stopLossPips = 1.3; // TODO: Put back to 1.3

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

    EAHelper::PlaceMarketOrder<TheProspector>(this, entry, stopLoss, 0.01);
    mBarCount = currentBars;
}

void TheProspector::ManageCurrentPendingSetupTicket()
{
    // we are placing market orders so we won't ever have pending orders
}

void TheProspector::ManageCurrentActiveSetupTicket()
{
    EAHelper::MoveToBreakEvenAsSoonAsPossible<TheProspector>(this);
}

bool TheProspector::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheProspector>(this, ticket);
}

void TheProspector::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TheProspector>(this, ticketIndex);
}

void TheProspector::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheProspector>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheProspector>(this);
}

void TheProspector::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheProspector>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheProspector>(this, ticketIndex);
}

void TheProspector::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheProspector>(this);
}

void TheProspector::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheProspector>(this, oldTicketIndex, newTicketNumber);
}

void TheProspector::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheProspector>(this, ticket, Period());
}

void TheProspector::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheProspector>(this, error, additionalInformation);
}

void TheProspector::Reset()
{
}
