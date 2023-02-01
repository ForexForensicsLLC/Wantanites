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
#include <SummitCapital/EAs/Inactive/CandleStick/CandleLiquidation/CandleLiquidation.mqh>

input string SymbolHeader = "US30 Symbol Name. Might Need to adjust for your broker";
input string ForcedSymbol = "US30";
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

CandleLiquidation *DLBuys;
CandleLiquidation *DLSells;

input string PipHeader = "Pip Values. Based on 2 Decimal Places in Symbol. Might need to adjust for your broker";
input double MinWickLengthPips = 200;
input double MaxSpreadPips = 25;
input double StopLossPaddingPips = 350;
input double PipsToWaitBeforeBE = 350;

input string TimeHeader = "Trading Time. Should be equal to 8:30 Central Time for default. Might need to adjust for your broker";
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

    DLBuys = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLBuys.mMinWickLength = MinWickLengthPips;
    DLBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    DLSells = new CandleLiquidation(MagicNumbers::DowMorningCandleLiquidationSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                    RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    DLSells.mMinWickLength = MinWickLengthPips;
    DLSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DLSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

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
