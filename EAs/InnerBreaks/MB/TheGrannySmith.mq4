//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/InnerBreaks/MB/TheGrannySmith.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("TheGrannySmith/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TheGrannySmith/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TheGrannySmith/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TheGrannySmith/Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheGrannySmith *AppleBuys;
TheGrannySmith *AppleSells;

// Nas
// double MaxSpreadPips = SymbolConstants::NasSpreadPips;
// double EntryPaddingPips = 10;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = SymbolConstants::NasSlippagePips;
// double LargeBodyPips = 100;
// double PushFurtherPips = 100;
// double CloseRR = 10;

// Dow
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 400;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double LargeBodyPips = 150;
// double PushFurtherPips = 150;
// double CloseRR = 10;

// S&P
// double MaxSpreadPips = SymbolConstants::SPXSpreadPips;
// double EntryPaddingPips = 5;
// double MinStopLossPips = 20;
// double StopLossPaddingPips = 10;
// double PipsToWaitBeforeBE = 50;
// double BEAdditionalPips = SymbolConstants::SPXSlippagePips;
// double LargeBodyPips = 20;
// double PushFurtherPips = 10;
// double CloseRR = 10;

// Gold - No Go
// double MaxSpreadPips = SymbolConstants::GoldSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 5;
// double StopLossPaddingPips = 1;
// double PipsToWaitBeforeBE = 20;
// double BEAdditionalPips = SymbolConstants::GoldSlippagePips;
// double LargeBodyPips = 10;
// double PushFurtherPips = 10;
// double CloseRR = 1000;

// UJ
// double MaxSpreadPips = 1;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 2;
// double StopLossPaddingPips = 1;
// double PipsToWaitBeforeBE = 20;
// double BEAdditionalPips = 1;
// double LargeBodyPips = 5;
// double PushFurtherPips = 5;
// double CloseRR = 2;

// EU
double MaxSpreadPips = 0.4;
double EntryPaddingPips = 0;
double MinStopLossPips = 2;
double StopLossPaddingPips = 0.5;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = 1;
double LargeBodyPips = 3;
double PushFurtherPips = 3;
double CloseRR = 2000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    AppleBuys = new TheGrannySmith(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT);
    AppleBuys.SetPartialCSVRecordWriter(PartialWriter);
    AppleBuys.AddPartial(CloseRR, 100);

    AppleBuys.mEntryPaddingPips = EntryPaddingPips;
    AppleBuys.mMinStopLossPips = MinStopLossPips;
    AppleBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    AppleBuys.mBEAdditionalPips = BEAdditionalPips;
    AppleBuys.mLargeBodyPips = LargeBodyPips;
    AppleBuys.mPushFurtherPips = PushFurtherPips;

    AppleBuys.AddTradingSession(16, 30, 23, 0);

    AppleSells = new TheGrannySmith(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                    ErrorWriter, SetupMBT);
    AppleSells.SetPartialCSVRecordWriter(PartialWriter);
    AppleSells.AddPartial(CloseRR, 100);

    AppleSells.mEntryPaddingPips = EntryPaddingPips;
    AppleSells.mMinStopLossPips = MinStopLossPips;
    AppleSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    AppleSells.mBEAdditionalPips = BEAdditionalPips;
    AppleSells.mLargeBodyPips = LargeBodyPips;
    AppleSells.mPushFurtherPips = PushFurtherPips;

    AppleSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete AppleBuys;
    delete AppleSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    AppleBuys.Run();
    AppleSells.Run();
}
