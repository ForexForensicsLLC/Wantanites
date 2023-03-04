//+------------------------------------------------------------------+
//|                                                   Luxembourg.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/TheDojiExchange/TheDojiExchange.mqh>

// --- EA Inputs ---
string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

double StopLossPaddingPips = 0;
double RiskPercent = 0.0;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

int SetupType = OP_BUY;

string StrategyName = "TheDojiExchagne/";
string EAName = "Luxembourg/";
string SetupTypeName = "Buys/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheDojiExchange *Luxembourg;

int OnInit()
{
    // Should only be running on EU on the 5 min
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    Luxembourg = new TheDojiExchange(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                     ErrorWriter, SetupMBT);

    Luxembourg.SetPartialCSVRecordWriter(PartialWriter);
    Luxembourg.AddPartial(20, 50);
    Luxembourg.AddPartial(1000, 100); // TODO: Lower

    Luxembourg.mFixedStopLossPips = 10;
    Luxembourg.mPipsToWaitBeforeBE = 1;
    Luxembourg.mBEAdditionalPips = 0.2;

    Luxembourg.AddTradingSession(10, 12);
    Luxembourg.AddTradingSession(16, 18);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete Luxembourg;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    Luxembourg.Run();
}
