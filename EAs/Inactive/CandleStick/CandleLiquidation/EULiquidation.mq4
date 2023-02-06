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
#include <WantaCapital/EAs/Inactive/CandleStick/CandleLiquidation/CandleLiquidation.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "EU/";
string SetupTypeName = "CandleLiquidation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

CandleLiquidation *DLBuys;
CandleLiquidation *DLSells;

double MinWickLength = 5;
double MaxSpreadPips = 1;
double StopLossPaddingPips = 10;
double PipsToWaitBeforeBE = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    DLBuys = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLBuys.mMinWickLength = MinWickLength;
    DLBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLBuys.AddTradingSession(15, 0, 16, 30);

    DLSells = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                    RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLSells.mMinWickLength = MinWickLength;
    DLSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLSells.AddTradingSession(15, 0, 16, 30);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete DLBuys;
    delete DLSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DLBuys.Run();
    DLSells.Run();
}
