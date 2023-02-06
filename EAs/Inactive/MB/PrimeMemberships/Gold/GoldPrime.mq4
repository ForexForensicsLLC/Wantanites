//+------------------------------------------------------------------+
//|                                        NasMovingAveragesBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/EAs/PrimeMemberships/PrimeMembership.mqh>

// --- EA Inputs ---
string ForcedSymbol = "XAU";
int ForcedTimeFrame = 60;

double StopLossPaddingPips = 0;
double RiskPercent = 1.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 4;

int BuySetupType = OP_BUY;
int BuyMagicNumber = MagicNumbers::GoldPrimeBuys;

int SellSetupType = OP_SELL;
int SellMagicNumber = MagicNumbers::GoldPrimeSells;

string StrategyName = "PrimeMemberships/";
string EAName = "Gold/";
string SetupTypeName = "BothAtOnce/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *GoldPrimeBuys;
PrimeMembership *GoldPrimeSells;

int OnInit()
{
    // ----------------- Buys ---------------------------
    // Should only be running on Gold on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    GoldPrimeBuys = new PrimeMembership(BuyMagicNumber, BuySetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                        EntryWriter, ExitWriter, ErrorWriter);
    GoldPrimeBuys.SetPartialCSVRecordWriter(PartialWriter);
    GoldPrimeBuys.AddPartial(1.1, 100); // add .1 to account for spread

    GoldPrimeBuys.mAdditionalEntryPips = 15;
    GoldPrimeBuys.mFixedStopLossPips = 20;
    GoldPrimeBuys.mPipsToWaitBeforeBE = 15;
    GoldPrimeBuys.mBEAdditionalPips = 7;

    // Time Restrictions on FTMO: 1:05 - 23:50
    GoldPrimeBuys.AddTradingSession(1, 5, 23, 49);
    // -----------------------------------------------

    // ------------------------- Sells -------------------------
    // Should only be running on Gold on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    GoldPrimeSells = new PrimeMembership(SellMagicNumber, SellSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                         EntryWriter, ExitWriter, ErrorWriter);
    GoldPrimeSells.SetPartialCSVRecordWriter(PartialWriter);
    GoldPrimeSells.AddPartial(1.1, 100); // add .1 to account for spread

    GoldPrimeSells.mAdditionalEntryPips = 15;
    GoldPrimeSells.mFixedStopLossPips = 20;
    GoldPrimeSells.mPipsToWaitBeforeBE = 15;
    GoldPrimeSells.mBEAdditionalPips = 7;

    // Time Restrictions on FTMO: 1:05 - 23:50
    GoldPrimeSells.AddTradingSession(1, 5, 23, 49);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete GoldPrimeBuys;
    delete GoldPrimeSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    GoldPrimeBuys.Run();
    GoldPrimeSells.Run();
}
