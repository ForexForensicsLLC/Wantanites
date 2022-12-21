//+------------------------------------------------------------------+
//|                                       NasMovingAveragesSells.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/PrimeMemberships/PrimeMembership.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US100";
int ForcedTimeFrame = 60;

double StopLossPaddingPips = 0;
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 10;

int SetupType = OP_SELL;
int MagicNumber = MagicNumbers::NasPrimeSells;

string StrategyName = "PrimeMemberships/";
string EAName = "Nas/";
string SetupTypeName = "Sells/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *NasPrime;

int OnInit()
{
    // Should only be running on Nas on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    NasPrime = new PrimeMembership(MagicNumber, SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter);
    NasPrime.SetPartialCSVRecordWriter(PartialWriter);
    NasPrime.AddPartial(1.1, 100); // add .1 to account for spread

    // Add 20 to everything to account for worst case entry due to spread
    NasPrime.mAdditionalEntryPips = 120;
    NasPrime.mFixedStopLossPips = 420;
    NasPrime.mPipsToWaitBeforeBE = 150;
    NasPrime.mBEAdditionalPips = 40;

    // Time Restrictions on FTMO: 1:05 - 23:50
    NasPrime.AddTradingSession(1, 5, 23, 49);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NasPrime;
    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NasPrime.Run();
}
