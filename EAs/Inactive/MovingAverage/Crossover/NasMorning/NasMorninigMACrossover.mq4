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

string ForcedSymbol = "NAS100";
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
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

NasMo *NMBBuys;
NasMorningBreak *NMBSells;

// Nas
double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = SymbolConstants::NasMinStopLossPips;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = SymbolConstants::NasMinStopLossPips;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    NMBBuys = new NasMorningBreak(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter);

    NMBBuys.SetPartialCSVRecordWriter(PartialWriter);

    NMBBuys.mCloseHour = CloseHour;
    NMBBuys.mCloseMinute = CloseMinute;
    NMBBuys.mEntryPaddingPips = EntryPaddingPips;
    NMBBuys.mMinStopLossPips = MinStopLossPips;
    NMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBBuys.mBEAdditionalPips = BEAdditionalPips;

    NMBBuys.AddTradingSession(16, 30, 16, 40);

    NMBSells = new NasMorningBreak(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter);
    NMBSells.SetPartialCSVRecordWriter(PartialWriter);

    NMBSells.mCloseHour = CloseHour;
    NMBSells.mCloseMinute = CloseMinute;
    NMBSells.mEntryPaddingPips = EntryPaddingPips;
    NMBSells.mMinStopLossPips = MinStopLossPips;
    NMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBSells.mBEAdditionalPips = BEAdditionalPips;

    NMBSells.AddTradingSession(16, 30, 16, 40);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NMBBuys;
    delete NMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NMBBuys.Run();
    NMBSells.Run();
}
