//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/CandleStick/CandleLiquidation/CandleLiquidation.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "Dow/";
string SetupTypeName = "CandleLiquidation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

CandleLiquidation *DLBuys;
CandleLiquidation *DLSells;

double MinWickLengthPips = 200;
double MaxSpreadPips = 25;
double StopLossPaddingPips = 350;
double PipsToWaitBeforeBE = 350;

int HourStart = 16;
int MinuteStart = 30;
int HourEnd = 16;
int MinuteEnd = 35;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    DLBuys = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLBuys.mMinWickLength = MinWickLengthPips;
    DLBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLBuys.AddTradingSession(TS);

    DLSells = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                    RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLSells.mMinWickLength = MinWickLengthPips;
    DLSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLSells.AddTradingSession(TS);

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
