//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/MagicNumbers.mqh>
#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Inactive/TimeRange/WickRange/WickRange.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "WickRange/";
string EAName = "UJ/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeRangeBreakout *TRB;
WickRange *WRBuys;
WickRange *WRSells;

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
    WRBuys = new WickRange(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, TRB);

    WRBuys.SetPartialCSVRecordWriter(PartialWriter);

    WRBuys.mCloseHour = CloseHour;
    WRBuys.mCloseMinute = CloseMinute;
    WRBuys.mEntryPaddingPips = EntryPaddingPips;
    WRBuys.mMinStopLossPips = MinStopLossPips;
    WRBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WRBuys.mBEAdditionalPips = BEAdditionalPips;

    WRBuys.AddTradingSession(2, 0, 23, 0);

    WRSells = new WickRange(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter, TRB);
    WRSells.SetPartialCSVRecordWriter(PartialWriter);

    WRSells.mCloseHour = CloseHour;
    WRSells.mCloseMinute = CloseMinute;
    WRSells.mEntryPaddingPips = EntryPaddingPips;
    WRSells.mMinStopLossPips = MinStopLossPips;
    WRSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WRSells.mBEAdditionalPips = BEAdditionalPips;

    WRSells.AddTradingSession(2, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TRB;

    delete WRBuys;
    delete WRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WRBuys.Run();
    WRSells.Run();
}
