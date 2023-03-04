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
#include <Wantanites/EAs/Inactive/CandleStick/EntryPipsAway/EntryPipsAway.mqh>

string ForcedSymbol = "XAU";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "Gold/";
string SetupTypeName = "EntryPipsAway/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

EntryPipsAway *EPABuys;
EntryPipsAway *EPASells;

// Gold
double PipsFromOpen = 100;
double MaxSpreadPips = 18;
double EntryPaddingPips = 0;
double MinStopLossPips = 100;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 80;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    EPABuys = new EntryPipsAway(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter);

    EPABuys.SetPartialCSVRecordWriter(PartialWriter);

    EPABuys.mPipsFromOpen = PipsFromOpen;
    EPABuys.mEntryPaddingPips = EntryPaddingPips;
    EPABuys.mMinStopLossPips = MinStopLossPips;
    EPABuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EPABuys.mBEAdditionalPips = BEAdditionalPips;

    EPABuys.AddTradingSession(0, 0, 23, 59);

    EPASells = new EntryPipsAway(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter);
    EPASells.SetPartialCSVRecordWriter(PartialWriter);

    EPASells.mPipsFromOpen = PipsFromOpen;
    EPASells.mEntryPaddingPips = EntryPaddingPips;
    EPASells.mMinStopLossPips = MinStopLossPips;
    EPASells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EPASells.mBEAdditionalPips = BEAdditionalPips;

    EPASells.AddTradingSession(0, 0, 23, 59);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EPABuys;
    delete EPASells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    EPABuys.Run();
    EPASells.Run();
}
