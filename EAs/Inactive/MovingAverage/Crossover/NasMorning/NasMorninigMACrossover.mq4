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
#include <WantaCapital/EAs/Inactive/MovingAverage/Crossover/NasMorning/NasMorningMACrossover.mqh>

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "MovingAverage/";
string EAName = "Crossover/";
string SetupTypeName = "NasMorning/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

NasMorningCrossover *NMCBuys;
NasMorningCrossover *NMCSells;

// Nas
double MaxSpreadPips = 25;
double StopLossPaddingPips = 250;
double PipsToWaitBeforeBE = 0.0;
double BEAdditionalPips = 0.0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    NMCBuys = new NasMorningCrossover(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter);

    NMCBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMCBuys.mBEAdditionalPips = BEAdditionalPips;
    NMCBuys.AddTradingSession(16, 30, 17, 0);

    NMCSells = new NasMorningCrossover(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                       ExitWriter, ErrorWriter);

    NMCSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMCSells.mBEAdditionalPips = BEAdditionalPips;
    NMCSells.AddTradingSession(16, 30, 17, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NMCBuys;
    delete NMCSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NMCBuys.Run();
    NMCSells.Run();
}
