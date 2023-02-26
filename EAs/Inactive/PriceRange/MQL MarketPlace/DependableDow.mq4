//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/EAs/Inactive/PriceRange/CloseOnCandleClose/CloseOnCandleClosePriceRange.mqh>
#include <WantaCapital/Framework/Helpers/MailHelper.mqh>

input string SymbolHeader = "==== Symbol Info ====";
input string SymbolInstructions = "US30 Symbol Name. Might Need to adjust for your broker";
input string SymbolToUse = "US30";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
input double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "DependableDow/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceRange *PRBuys;
PriceRange *PRSells;

TradingSession *TS;

input string MagicNumbersHeader = "==== Magic Numbers ===";
input int MagicNumberBuys = -1;
input int MagicNumberSells = -2;

input string PipHeader = "==== Pip Values ====";
input string PipInstructions = "Pip Values. Based on 2 Decimal Places in Symbol. Might need to adjust for your broker";
input double PipsFromOpen = 250;
input double MaxSpreadPips = 25;
double StopLossPaddingPips = 0;

input string TimeHeader = "==== Time Values ====";
input string TimeInstructions = "Trading Time. Should be equal to 16:30 GMT+3 for default. Might need to adjust for your broker";
input int HourStart = 16;
input int MinuteStart = 30;
input int HourEnd = 19;
input int MinuteEnd = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(SymbolToUse, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    PRBuys = new PriceRange(MagicNumberBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter);

    PRBuys.mPipsFromOpen = PipsFromOpen;
    PRBuys.AddTradingSession(TS);

    PRSells = new PriceRange(MagicNumberSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                             EntryWriter, ExitWriter, ErrorWriter);

    PRSells.mPipsFromOpen = PipsFromOpen;
    PRSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PRBuys;
    delete PRSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;

    MailHelper::SendEADeinitEmail(Directory, reason);
}

void OnTick()
{
    PRBuys.Run();
    PRSells.Run();
}
