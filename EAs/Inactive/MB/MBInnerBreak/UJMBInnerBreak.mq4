//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Inactive/MB/MBInnerBreak/MBInnerBreak.mqh>
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>

// --- EA Inputs ---
double RiskPercent = 0.1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "MBInnerBreak/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

MBInnerBreak *MBInnerBreakBuys;
MBInnerBreak *MBInnerBreakSells;

double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = 2;
double StopLossPaddingPips = 1;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = 1;
double LargeBodyPips = 5;
double PushFurtherPips = 5;
double CloseRR = 3;

int OnInit()
{
    TS = new TradingSession();

    MBInnerBreakBuys = new MBInnerBreak(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                        ExitWriter, ErrorWriter, MBT);

    MBInnerBreakBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakBuys.AddPartial(CloseRR, 100);

    MBInnerBreakBuys.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakBuys.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakBuys.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakBuys.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakBuys.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakBuys.AddTradingSession(TS);

    MBInnerBreakSells = new MBInnerBreak(-1, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                         ExitWriter, ErrorWriter, MBT);
    MBInnerBreakSells.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakSells.AddPartial(CloseRR, 100);

    MBInnerBreakSells.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakSells.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakSells.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakSells.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakSells.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete MBInnerBreakBuys;
    delete MBInnerBreakSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBInnerBreakBuys.Run();
    MBInnerBreakSells.Run();
}
