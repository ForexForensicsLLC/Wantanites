//+------------------------------------------------------------------+
//|                                                    HTFZoneLTFDoji.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class HTFZoneLTFDoji : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    ENUM_TIMEFRAMES mLowerTimeFrame;
    double mMinWickPips;

    int mCurrentTradeOnZone;

    ObjectList<Zone> *mZones;
    Dictionary<string, int> *mObjectNameZoneNumbers;

public:
    HTFZoneLTFDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~HTFZoneLTFDoji();

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
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

HTFZoneLTFDoji::HTFZoneLTFDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mCurrentTradeOnZone = ConstantValues::EmptyInt;

    mZones = new ObjectList<Zone>();
    mObjectNameZoneNumbers = new Dictionary<string, int>();

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<HTFZoneLTFDoji>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<HTFZoneLTFDoji, SingleTimeFrameEntryTradeRecord>(this);
}

HTFZoneLTFDoji::~HTFZoneLTFDoji()
{
    delete mZones;
    delete mObjectNameZoneNumbers;
}

void HTFZoneLTFDoji::PreRun()
{
    EARunHelper::ShowOpenTicketProfit<HTFZoneLTFDoji>(this);
    for (int i = 0; i < ObjectsTotal(); i++)
    {
        string name = ObjectName(i);
        string description = ObjectGetString(MQLHelper::CurrentChartID(), name, OBJPROP_TEXT);
        if (ObjectType(name) != OBJ_RECTANGLE)
        {
            continue;
        }

        if (StringFind(description, "Zone") == -1)
        {
            double priceOne = ObjectGet(name, OBJPROP_PRICE1);
            double priceTwo = ObjectGet(name, OBJPROP_PRICE2);

            double entryPrice = ConstantValues::EmptyDouble;
            double exitPrice = ConstantValues::EmptyDouble;

            // demand zone
            if (CurrentTick().Ask() > priceOne && CurrentTick().Ask() > priceTwo)
            {
                if (SetupType() == SignalType::Bearish)
                {
                    continue;
                }

                if (priceOne > priceTwo)
                {
                    entryPrice = priceOne;
                    exitPrice = priceTwo;
                }
                else
                {
                    entryPrice = priceTwo;
                    exitPrice = priceOne;
                }
            }
            // supply zone
            else if (CurrentTick().Ask() < priceOne && CurrentTick().Ask() < priceTwo)
            {
                if (SetupType() == SignalType::Bullish)
                {
                    continue;
                }

                if (priceOne < priceTwo)
                {
                    entryPrice = priceOne;
                    exitPrice = priceTwo;
                }
                else
                {
                    entryPrice = priceTwo;
                    exitPrice = priceOne;
                }
            }

            color zoneClr = SetupType() == SignalType::Bullish ? clrLimeGreen : clrRed;
            Zone *zone = new Zone(false, EntrySymbol(), EntryTimeFrame(), 0, i, SetupType(), "Zone",
                                  ObjectGet(name, OBJPROP_TIME1),
                                  entryPrice,
                                  ObjectGet(name, OBJPROP_TIME2),
                                  exitPrice,
                                  0, CandlePart::Body, zoneClr);

            zone.Draw();
            mZones.Add(zone);

            ObjectSetString(MQLHelper::CurrentChartID(), zone.ObjectName(), OBJPROP_TEXT, "Zone");
            ObjectSetString(MQLHelper::CurrentChartID(), name, OBJPROP_TEXT, "Zone");

            mObjectNameZoneNumbers.Add(name, i);
        }
    }
}

bool HTFZoneLTFDoji::AllowedToTrade()
{
    return EARunHelper::BelowSpread<HTFZoneLTFDoji>(this) && EARunHelper::WithinTradingSession<HTFZoneLTFDoji>(this);
}

void HTFZoneLTFDoji::CheckSetSetup()
{
    mHasSetup = mZones.Size() > 0;
}

void HTFZoneLTFDoji::CheckInvalidateSetup()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    for (int i = 0; i < mObjectNameZoneNumbers.Size(); i++)
    {
        if (ObjectFind(MQLHelper::CurrentChartID(), mObjectNameZoneNumbers.GetKey(i)) < 0)
        {
            mZones.RemoveWhere<TZoneNumberLocator, int>(Zone::LocateByNumber, mObjectNameZoneNumbers.GetValue(i));
        }
    }

    for (int i = mZones.Size() - 1; i >= 0; i--)
    {
        if (mZones[i].IsBroken())
        {
            mZones.Remove(i);
        }
    }

    if (mZones.IsEmpty())
    {
        InvalidateSetup(false);
    }

    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void HTFZoneLTFDoji::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<HTFZoneLTFDoji>(this, deletePendingOrder, mStopTrading, error);
}

bool HTFZoneLTFDoji::Confirmation()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    bool hasHoldingZone = false;
    Zone *holdingZone;

    for (int i = 0; i < mZones.Size(); i++)
    {
        if (mZones[i].IsHoldingFromStart())
        {
            holdingZone = mZones[i];
            hasHoldingZone = true;
            break;
        }
    }

    if (!hasHoldingZone)
    {
        return false;
    }

    if (!EASetupHelper::CandleIsInZone<HTFZoneLTFDoji>(this, holdingZone, 1, true))
    {
        return false;
    }

    bool dojiInZone = false;

    // TODO: Add checks for overall candle size i.e. make sure its more of a doji and not a huge body that liquidated the candle before it
    if (SetupType() == SignalType::Bullish)
    {
        dojiInZone = SetupHelper::HammerCandleStickPattern(EntrySymbol(), mLowerTimeFrame, 1) &&
                     CandleStickHelper::LowerWickLength(EntrySymbol(), mLowerTimeFrame, 1) >= PipConverter::PipsToPoints(mMinWickPips);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        dojiInZone = SetupHelper::ShootingStarCandleStickPattern(EntrySymbol(), mLowerTimeFrame, 1) &&
                     CandleStickHelper::UpperWickLength(EntrySymbol(), mLowerTimeFrame, 1) >= PipConverter::PipsToPoints(mMinWickPips);
    }

    mCurrentTradeOnZone = holdingZone.Number();
    return dojiInZone;
}

void HTFZoneLTFDoji::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = iLow(EntrySymbol(), EntryTimeFrame(), 1);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = iHigh(EntrySymbol(), EntryTimeFrame(), 1);
    }

    EAOrderHelper::PlaceMarketOrder<HTFZoneLTFDoji>(this, entry, stopLoss);
}

void HTFZoneLTFDoji::PreManageTickets()
{
}

void HTFZoneLTFDoji::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void HTFZoneLTFDoji::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool HTFZoneLTFDoji::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void HTFZoneLTFDoji::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void HTFZoneLTFDoji::CheckCurrentSetupTicket(Ticket &ticket)
{
    // Make sure we are only ever losing how much we intend to risk, even if we entered at a worse price due to slippage
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if ((AccountInfoDouble(ACCOUNT_EQUITY) - accountBalance) / accountBalance * 100 <= -RiskPercent())
    {
        ticket.Close();
    }
}

void HTFZoneLTFDoji::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void HTFZoneLTFDoji::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<HTFZoneLTFDoji>(this, ticket);
}

void HTFZoneLTFDoji::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void HTFZoneLTFDoji::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<HTFZoneLTFDoji>(this, ticket);

    for (int i = 0; i < mZones.Size(); i++)
    {
        if (mZones[i].Number() == mCurrentTradeOnZone)
        {
            mZones.Remove(i);
            mCurrentTradeOnZone = ConstantValues::EmptyInt;
        }
    }
}

void HTFZoneLTFDoji::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<HTFZoneLTFDoji>(this, methodName, error, additionalInformation);
}

bool HTFZoneLTFDoji::ShouldReset()
{
    return false;
}

void HTFZoneLTFDoji::Reset()
{
}