//+------------------------------------------------------------------+
//|                                       NasMovingAveragesSells.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Giovanni/Giovanni.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US100";
int ForcedTimeFrame = 1;

double StopLossPaddingPips = 0;
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 10;

int SetupType = OP_SELL;

string StrategyName = "Giovanni/";
string EAName = "";
string SetupTypeName = "Sells/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

Giovanni *G;

int OnInit()
{
    // Should only be running on Nas on the 1 min
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    G = new Giovanni(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    G.SetPartialCSVRecordWriter(PartialWriter);
    G.AddPartial(3, 100);

    G.mAdditionalEntryPips = 60;
    G.mFixedStopLossPips = 60;
    G.mPipsToWaitBeforeBE = 60;
    G.mBEAdditionalPips = 12; // A tad bit more than spread

    G.AddTradingSession(16, 30, 16, 40);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete G;
    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    G.Run();
}
