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
string ForcedSymbol = "US30";
int ForcedTimeFrame = 60;

double StopLossPaddingPips = 0;
double RiskPercent = 1.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 20;

int BuySetupType = OP_BUY;
int BuyMagicNumber = MagicNumbers::GoldPrimeBuys;

int SellSetupType = OP_SELL;
int SellMagicNumber = MagicNumbers::GoldPrimeSells;

string StrategyName = "PrimeMemberships/";
string EAName = "Dow/";
string SetupTypeName = "BothAtOnce/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *DowPrimeBuys;
PrimeMembership *DowPrimeSells;

double AdditionalEntryPips = 300;
double FixedStopLossPips = 450;
double PipsToWaitBeforeBE = 300;
double BEAdditionalPips = 50;

int OnInit()
{
    // ----------------- Buys ---------------------------
    // Should only be running on Gold on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    DowPrimeBuys = new PrimeMembership(BuyMagicNumber, BuySetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                       EntryWriter, ExitWriter, ErrorWriter);
    DowPrimeBuys.SetPartialCSVRecordWriter(PartialWriter);
    DowPrimeBuys.AddPartial(1.1, 100); // add .1 to account for spread

    DowPrimeBuys.mAdditionalEntryPips = AdditionalEntryPips;
    DowPrimeBuys.mFixedStopLossPips = FixedStopLossPips;
    DowPrimeBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DowPrimeBuys.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: 1:05 - 23:50
    DowPrimeBuys.AddTradingSession(1, 5, 23, 49);
    // -----------------------------------------------

    // ------------------------- Sells -------------------------
    // Should only be running on Gold on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    DowPrimeSells = new PrimeMembership(SellMagicNumber, SellSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                        EntryWriter, ExitWriter, ErrorWriter);
    DowPrimeSells.SetPartialCSVRecordWriter(PartialWriter);
    DowPrimeSells.AddPartial(1.1, 100); // add .1 to account for spread

    DowPrimeSells.mAdditionalEntryPips = AdditionalEntryPips;
    DowPrimeSells.mFixedStopLossPips = FixedStopLossPips;
    DowPrimeSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DowPrimeSells.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: 1:05 - 23:50
    DowPrimeSells.AddTradingSession(1, 5, 23, 49);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete DowPrimeBuys;
    delete DowPrimeSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DowPrimeBuys.Run();
    DowPrimeSells.Run();
}