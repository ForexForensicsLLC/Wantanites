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
#include <Wantanites/EAs/Inactive/News/EnterBefore/Hedge/EnterBeforeNewsHedge.mqh>

string ForcedSymbol = "NAS100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "News/";
string EAName = "UJ/";
string SetupTypeName = "EnterBeforeHedge/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

EnterBeforeNewsHedge *EBNHBuys;
EnterBeforeNewsHedge *EBNHSells;

// NAS
double MaxSpreadPips = 3;
double StopLossPaddingPips = 25;
double PipsToWaitBeforeBE = 100;
double BEAdditionalPips = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(14, 30, 22, 0);

    EBNHBuys = new EnterBeforeNewsHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                        RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    EBNHBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHBuys.mBEAdditionalPips = BEAdditionalPips;
    EBNHBuys.AddTradingSession(TS);

    EBNHSells = new EnterBeforeNewsHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                         MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    EBNHSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHSells.mBEAdditionalPips = BEAdditionalPips;
    EBNHSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EBNHBuys;
    delete EBNHSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    EBNHBuys.Run();
    EBNHSells.Run();
}
