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
#include <Wantanites/EAs/Inactive/TimeRange/TimeRangeBreakout/StartOfDayTimeRangeBreakout.mqh>

string ForcedSymbol = "XAU";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeRangeBreakout/";
string EAName = "Gold/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeRangeBreakout *TRB;
StartOfDayTimeRangeBreakout *TRBBuys;
StartOfDayTimeRangeBreakout *TRBSells;

// Gold
int CloseHour = 20;
int CloseMinute = 0;
double MaxSpreadPips = 3;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TRB = new TimeRangeBreakout(8, 0, 10, 0);
    TRBBuys = new StartOfDayTimeRangeBreakout(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                              ExitWriter, ErrorWriter, TRB);

    TRBBuys.SetPartialCSVRecordWriter(PartialWriter);

    TRBBuys.mCloseHour = CloseHour;
    TRBBuys.mCloseMinute = CloseMinute;
    TRBBuys.mEntryPaddingPips = EntryPaddingPips;
    TRBBuys.mMinStopLossPips = MinStopLossPips;
    TRBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TRBBuys.mBEAdditionalPips = BEAdditionalPips;

    TRBBuys.AddTradingSession(10, 0, 23, 0);

    TRBSells = new StartOfDayTimeRangeBreakout(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                               ExitWriter, ErrorWriter, TRB);
    TRBSells.SetPartialCSVRecordWriter(PartialWriter);

    TRBSells.mCloseHour = CloseHour;
    TRBSells.mCloseMinute = CloseMinute;
    TRBSells.mEntryPaddingPips = EntryPaddingPips;
    TRBSells.mMinStopLossPips = MinStopLossPips;
    TRBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TRBSells.mBEAdditionalPips = BEAdditionalPips;

    TRBSells.AddTradingSession(10, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TRB;

    delete TRBBuys;
    delete TRBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TRBBuys.Run();
    TRBSells.Run();
}
