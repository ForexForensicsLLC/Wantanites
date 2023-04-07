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
#include <Wantanites/EAs/Inactive/PriceRange/Hedge/PriceRangeHedge.mqh>
#include <Wantanites/Framework/Helpers/MailHelper.mqh>

string ForcedSymbol = "XAUUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "PriceRange/";
string EAName = "XAU/";
string SetupTypeName = "Hedge/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceRange *PRBuys;
PriceRange *PRSells;

TradingSession *TS;

double PipsFromOpen = 30;
double MaxSpreadPips = 5;
double StopLossPaddingPips = -20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(11, 0, 23, 0);

    PRBuys = new PriceRange(-1, EMPTY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter);

    PRBuys.mPipsFromOpen = PipsFromOpen;
    PRBuys.AddTradingSession(TS);

    // PRSells = new PriceRange(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
    //                          EntryWriter, ExitWriter, ErrorWriter);

    // PRSells.mCloseHour = CloseHour;
    // PRSells.mCloseMinute = CloseMinute;
    // PRSells.mPipsFromOpen = PipsFromOpen;
    // PRSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PRBuys;
    // delete PRSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;

    MailHelper::SendEADeinitEmail(Directory, reason);
}

void OnTick()
{
    PRBuys.Run();
    // PRSells.Run();
}
