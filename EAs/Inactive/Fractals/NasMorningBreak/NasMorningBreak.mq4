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

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "NasMorningBreak/";
string EAName = "Nas/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

NasMorningBreak *NMBBuys;
NasMorningBreak *NMBSells;

// Nas
int CloseHour = 20;
int CloseMinute = 0;
double MaxSpreadPips = 25;
double StopLossPaddingPips = 250;
double PipsToWaitBeforeBE = 250;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    NMBBuys = new NasMorningBreak(MagicNumbers::NasMorningFractalBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                  RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    NMBBuys.mCloseHour = CloseHour;
    NMBBuys.mCloseMinute = CloseMinute;
    NMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBBuys.AddTradingSession(16, 30, 16, 40);

    NMBSells = new NasMorningBreak(MagicNumbers::NasMorningFractalBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    NMBSells.mCloseHour = CloseHour;
    NMBSells.mCloseMinute = CloseMinute;
    NMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBSells.AddTradingSession(16, 30, 16, 40);

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
