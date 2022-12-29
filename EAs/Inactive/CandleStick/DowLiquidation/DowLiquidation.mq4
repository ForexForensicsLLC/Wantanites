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
#include <SummitCapital/EAs/Inactive/CandleStick/DowLiquidation/DowLiquidation.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "Dow/";
string SetupTypeName = "DowLiquidation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

DowLiquidation *DLBuys;
DowLiquidation *DLSells;

// Dow
double MinWickLength = 20;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = SymbolConstants::DowMinStopLossPips;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = SymbolConstants::DowMinStopLossPips;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    DLBuys = new DowLiquidation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter);

    DLBuys.SetPartialCSVRecordWriter(PartialWriter);

    DLBuys.mMinWickLength = MinWickLength;
    DLBuys.mEntryPaddingPips = EntryPaddingPips;
    DLBuys.mMinStopLossPips = MinStopLossPips;
    DLBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLBuys.mBEAdditionalPips = BEAdditionalPips;
    DLBuys.AddPartial(1, 100);

    DLBuys.AddTradingSession(16, 30, 16, 35);

    DLSells = new DowLiquidation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter);
    DLSells.SetPartialCSVRecordWriter(PartialWriter);

    DLSells.mMinWickLength = MinWickLength;
    DLSells.mEntryPaddingPips = EntryPaddingPips;
    DLSells.mMinStopLossPips = MinStopLossPips;
    DLSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLSells.mBEAdditionalPips = BEAdditionalPips;
    DLSells.AddPartial(1, 100);

    DLSells.AddTradingSession(16, 30, 16, 35);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete DLBuys;
    delete DLSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DLBuys.Run();
    DLSells.Run();
}
