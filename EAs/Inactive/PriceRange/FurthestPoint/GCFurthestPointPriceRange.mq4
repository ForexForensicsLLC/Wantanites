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
#include <Wantanites/EAs/Inactive/PriceRange/FurthestPoint/FurthestPointPriceRange.mqh>
#include <Wantanites/Framework/Helpers/MailHelper.mqh>

string ForcedSymbol = "GBPCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
input double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "PriceRange/";
string EAName = "GC/";
string SetupTypeName = "FurthestPoint/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceRange *PRBuys;
PriceRange *PRSells;

TradingSession *TS;

int FurthestThreshold = 30;
double PipsFromOpen = 10;
double MaxSpreadPips = 2;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(14, 0, 16, 0);

    PRBuys = new PriceRange(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter);

    PRBuys.mFurthestThreshold = FurthestThreshold;
    PRBuys.mPipsFromOpen = PipsFromOpen;
    PRBuys.AddTradingSession(TS);
    PRBuys.AddPartial(10, 50);
    PRBuys.SetPartialCSVRecordWriter(PartialWriter);

    PRSells = new PriceRange(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                             EntryWriter, ExitWriter, ErrorWriter);

    PRSells.mFurthestThreshold = FurthestThreshold;
    PRSells.mPipsFromOpen = PipsFromOpen;
    PRSells.AddTradingSession(TS);
    PRSells.AddPartial(10, 50);
    PRSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PRBuys;
    delete PRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;

    MailHelper::SendEADeinitEmail(Directory, reason);
}

void OnTick()
{
    PRBuys.Run();
    PRSells.Run();
}
