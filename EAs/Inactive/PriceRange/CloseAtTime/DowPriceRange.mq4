//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/MagicNumbers.mqh>
#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Inactive/PriceRange/PriceRange.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "PriceRange/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceRange *PRBuys;
PriceRange *PRSells;

// Nas
int CloseHour = 19;
int CloseMinute = 0;
double PipsFromOpen = 250;
// this needs to be higher than the spread before the session since the spread doesn't drop right as the candle opens and we only calaculte once per bar
double MaxSpreadPips = 25;
double StopLossPaddingPips = 0;

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
    PRBuys.AddTradingSession(16, 30, 16, 35);

    PRSells = new PriceRange(MagicNumbers::NasMorningPriceRangeSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                             EntryWriter, ExitWriter, ErrorWriter);

    PRSells.mCloseHour = CloseHour;
    PRSells.mCloseMinute = CloseMinute;
    PRSells.mPipsFromOpen = PipsFromOpen;
    PRSells.AddTradingSession(16, 30, 16, 35);

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
