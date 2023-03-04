//+------------------------------------------------------------------+
//|                                        NasMovingAveragesBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/PrimeMemberships/PrimeMembership.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US100";
int ForcedTimeFrame = 15;

double StopLossPaddingPips = 0;
double RiskPercent = .01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 25;

int BuysSetupType = OP_BUY;
int BuysMagicNumber = MagicNumbers::NasPrimeBuys;

int SellsSetupType = OP_SELL;
int SellsMagicNumber = MagicNumbers::NasPrimeSells;

string StrategyName = "PrimeMemberships/";
string EAName = "Nas/";
string SetupTypeName = "BothAtOnce/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *NasPrimeBuys;
PrimeMembership *NasPrimeSells;

// 1h
// double AdditionalEntryPips = 120;
// double FixedStopLossPips = 230;
// double PipsToWaitBeforeBE = 150;
// double BEAdditionalPips = 40;

// 15 min
// double AdditionalEntryPips = 50;
// double FixedStopLossPips = 150;  // was 150
// double PipsToWaitBeforeBE = 150; // was 150
// double BEAdditionalPips = 50;    // was 50

// 15 min Lil Dipper
double AdditionalEntryPips = 50;
double FixedStopLossPips = 250;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = 50;

int OnInit()
{
    // Should only be running on Nas on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    // ------------ Buys------------------
    NasPrimeBuys = new PrimeMembership(BuysMagicNumber, BuysSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                       EntryWriter, ExitWriter, ErrorWriter);
    NasPrimeBuys.SetPartialCSVRecordWriter(PartialWriter);
    NasPrimeBuys.AddPartial(1000, 100); // add .03 to account for spread

    // Add 20 to everything to account for worst case entry due to spread
    NasPrimeBuys.mAdditionalEntryPips = AdditionalEntryPips;
    NasPrimeBuys.mFixedStopLossPips = FixedStopLossPips; //  was 420
    NasPrimeBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NasPrimeBuys.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: GMT+3 1:05 - 23:50
    // NasPrimeBuys.AddTradingSession(1, 5, 23, 49);
    NasPrimeBuys.AddTradingSession(16, 0, 23, 0);

    // -----------------------------------

    // ----------- Sells -----------------
    NasPrimeSells = new PrimeMembership(SellsMagicNumber, SellsSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                        EntryWriter, ExitWriter, ErrorWriter);
    NasPrimeSells.SetPartialCSVRecordWriter(PartialWriter);
    NasPrimeSells.AddPartial(1000, 100); // add .03 to account for spread

    // Add 20 to everything to account for worst case entry due to spread
    NasPrimeSells.mAdditionalEntryPips = AdditionalEntryPips;
    NasPrimeSells.mFixedStopLossPips = FixedStopLossPips; // was 420
    NasPrimeSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NasPrimeSells.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: GMT+3 1:05 - 23:50
    // NasPrimeSells.AddTradingSession(1, 5, 23, 49);
    NasPrimeSells.AddTradingSession(16, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NasPrimeBuys;
    delete NasPrimeSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NasPrimeBuys.Run();
    NasPrimeSells.Run();
}
