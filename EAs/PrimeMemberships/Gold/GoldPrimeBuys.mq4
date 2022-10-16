//+------------------------------------------------------------------+
//|                                        NasMovingAveragesBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/PrimeMemberships/PrimeMembership.mqh>

// --- EA Inputs ---
string ForcedSymbol = "XAU";
int ForcedTimeFrame = 60;

double StopLossPaddingPips = 0;
double RiskPercent = 0.01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 4;

int SetupType = OP_BUY;
int MagicNumber = MagicNumbers::GoldPrimeBuys;

string StrategyName = "PrimeMemberships/";
string EAName = "Gold/";
string SetupTypeName = "Buys/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *GoldPrime;

int OnInit()
{
    // Should only be running on Gold on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    GoldPrime = new PrimeMembership(MagicNumber, SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter);
    GoldPrime.SetPartialCSVRecordWriter(PartialWriter);
    GoldPrime.AddPartial(1.1, 100); // add .1 to account for spread

    GoldPrime.mAdditionalEntryPips = 15;
    GoldPrime.mFixedStopLossPips = 20;
    GoldPrime.mPipsToWaitBeforeBE = 10;
    GoldPrime.mBEAdditionalPips = 4;

    // Time Restrictions on FTMO: 1:05 - 23:50
    GoldPrime.AddTradingSession(1, 5, 23, 49);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete GoldPrime;
    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    GoldPrime.Run();
}
