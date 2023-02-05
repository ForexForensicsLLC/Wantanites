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
#include <SummitCapital/EAs/Inactive/Fractals/NasMorningBreak/NasMorningBreak.mqh>

input string SymbolHeader = "US100 Symbol Name. Might Need to adjust for your broker";
input string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
input double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TheNasRazzleDazzle/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

NasMorningBreak *NMBBuys;
NasMorningBreak *NMBSells;

// Nas
input string PipHeader = "Pip Values. Based on 2 Decimal Places in Symbol. Might need to adjust for your broker";
input double MaxSpreadPips = 25;
input double StopLossPaddingPips = 250;
input double PipsToWaitBeforeBE = 250;

input string TradingTime = "Trading Time. Should be equal to 16:30 GMT+3 for default. Might need to adjust for your broker";
input int HourStart = 16;
input int MinuteStart = 30;
input int HourEnd = 16;
input int MinuteEnd = 40;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    NMBBuys = new NasMorningBreak(MagicNumbers::NasMorningFractalBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                  RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    NMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    NMBSells = new NasMorningBreak(MagicNumbers::NasMorningFractalBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    NMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NMBBuys;
    delete NMBSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NMBBuys.Run();
    NMBSells.Run();
}
