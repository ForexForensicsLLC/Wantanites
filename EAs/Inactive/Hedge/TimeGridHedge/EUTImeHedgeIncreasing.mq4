//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/MagicNumbers.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Inactive/Hedge/TimeHedge/TimeHedgeIncreasing.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Hedge/";
string EAName = "EU/";
string SetupTypeName = "TimeHedge/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeHedge *THBuys;
TimeHedge *THSells;

// Nas
double CloseEquityPercentGain = 0.5;
double CloseEquityPercentLoss = -0.5;
double LotSize = 1;
int CloseHour = 23;
int CloseMinute = 0;
double OriginalOrdersPipsFromOpen = 15;
double HedgeOrderPipsFromOpen = 19;
// this needs to be higher than the spread before the session since the spread doesn't drop right as the candle opens and we only calaculte once per bar
double MaxSpreadPips = 1;
double StopLossPaddingPips = 0;

int HourStart = 11;
int MinuteStart = 0;
int HourEnd = 23;
int MinuteEnd = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    THBuys = new TimeHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                           EntryWriter, ExitWriter, ErrorWriter);

    THBuys.mCloseEquityPercentGain = CloseEquityPercentGain;
    THBuys.mCloseEquityPercentLoss = CloseEquityPercentLoss;
    THBuys.mLotSize = LotSize;
    THBuys.mCloseHour = CloseHour;
    THBuys.mCloseMinute = CloseMinute;
    THBuys.mPipsFromOpen = OriginalOrdersPipsFromOpen;

    THBuys.SetPartialCSVRecordWriter(PartialWriter);
    THBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    THSells = new TimeHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter);

    THSells.mCloseEquityPercentGain = CloseEquityPercentGain;
    THSells.mCloseEquityPercentLoss = CloseEquityPercentLoss;
    THSells.mLotSize = LotSize;
    THSells.mCloseHour = CloseHour;
    THSells.mCloseMinute = CloseMinute;
    THSells.mPipsFromOpen = HedgeOrderPipsFromOpen;

    THSells.SetPartialCSVRecordWriter(PartialWriter);
    THSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete THBuys;
    delete THSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    THBuys.Run();
    THSells.Run();
}
