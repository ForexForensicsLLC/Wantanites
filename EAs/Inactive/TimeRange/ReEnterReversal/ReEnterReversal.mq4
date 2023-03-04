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
#include <Wantanites/EAs/Inactive/TimeRange/ReEnterReversal/ReEnterReversal.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "ReEnterReversal/";
string EAName = "UJ/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeRangeBreakout *TRB;
ReEnterReversal *TRBBuys;
ReEnterReversal *TRBSells;

// UJ
int CloseHour = 23;
int CloseMinute = 0;
double MaxSpreadPips = 1.5;
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

    TRB = new TimeRangeBreakout(0, 0, 2, 0);
    TRBBuys = new ReEnterReversal(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, TRB);

    TRBBuys.SetPartialCSVRecordWriter(PartialWriter);

    TRBBuys.mCloseHour = CloseHour;
    TRBBuys.mCloseMinute = CloseMinute;
    TRBBuys.mEntryPaddingPips = EntryPaddingPips;
    TRBBuys.mMinStopLossPips = MinStopLossPips;
    TRBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TRBBuys.mBEAdditionalPips = BEAdditionalPips;

    TRBBuys.AddTradingSession(2, 0, 23, 0);

    TRBSells = new ReEnterReversal(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter, TRB);
    TRBSells.SetPartialCSVRecordWriter(PartialWriter);

    TRBSells.mCloseHour = CloseHour;
    TRBSells.mCloseMinute = CloseMinute;
    TRBSells.mEntryPaddingPips = EntryPaddingPips;
    TRBSells.mMinStopLossPips = MinStopLossPips;
    TRBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TRBSells.mBEAdditionalPips = BEAdditionalPips;

    TRBSells.AddTradingSession(2, 0, 23, 0);

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
