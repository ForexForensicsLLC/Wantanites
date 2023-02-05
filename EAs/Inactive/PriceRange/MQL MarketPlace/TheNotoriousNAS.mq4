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
#include <SummitCapital/EAs/Inactive/PriceRange/PriceRange.mqh>

input string SymbolHeader = "US100 Symbol Name. Might Need to adjust for your broker";
input string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
input double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TheNotoriousNAS/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceRange *PRBuys;
PriceRange *PRSells;

// Nas
input string PipHeader = "Pip Values. Based on 2 Decimal Places in Symbol. Might need to adjust for your broker";
input double PipsFromOpen = 250;
// this needs to be higher than the spread before the session since the spread doesn't drop right as the candle opens and we only calaculte once per bar
input double MaxSpreadPips = 25;
double StopLossPaddingPips = 0;

input string CloseTime = "Close Ticket Time. Should be equal to 23:00 GMT+3 for default. Might need to adjust for your broker";
input int CloseHour = 23; // TODO: Switch to 23 when using on my own account for a lot more profits. Using 19 only for Prop Firms
input int CloseMinute = 0;

input string TradingTime = "Trading Time. Should be equal to 16:30 GMT+3 for default. Might need to adjust for your broker";
input int HourStart = 16;
input int MinuteStart = 30;
input int HourEnd = 16;
input int MinuteEnd = 35;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    PRBuys = new PriceRange(MagicNumbers::NasMorningPriceRangeBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter);

    PRBuys.mCloseHour = CloseHour;
    PRBuys.mCloseMinute = CloseMinute;
    PRBuys.mPipsFromOpen = PipsFromOpen;
    PRBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    PRSells = new PriceRange(MagicNumbers::NasMorningPriceRangeSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                             EntryWriter, ExitWriter, ErrorWriter);

    PRSells.mCloseHour = CloseHour;
    PRSells.mCloseMinute = CloseMinute;
    PRSells.mPipsFromOpen = PipsFromOpen;
    PRSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PRBuys;
    delete PRSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    PRBuys.Run();
    PRSells.Run();
}
