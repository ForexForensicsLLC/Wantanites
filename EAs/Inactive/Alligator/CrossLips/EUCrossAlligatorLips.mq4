//+------------------------------------------------------------------+
//|                                                    CALBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Inactive/Alligator/CrossLips/CrossAlligatorLips.mqh>

// --- EA Inputs ---
string ForcedSymbol = "EU";
int ForcedTimeFrame = 5;

double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Alligator/";
string EAName = "EU/";
string SetupTypeName = "CrossLips";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

CrossAlligatorLips *CALBuys;
CrossAlligatorLips *CALSells;

double MaxSpreadPips = 3;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = 50;
double MaxPipsFromGreenLips = 1200;
double MinBlueRedAlligatorGap = .00015;
double MinRedGreenAlligatorGap = .00015;
double MinWickLength = 0;
double CloseRR = 2;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(11, 0, 23, 0);

    CALBuys = new CrossAlligatorLips(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                     ErrorWriter);

    CALBuys.SetPartialCSVRecordWriter(PartialWriter);
    CALBuys.AddPartial(CloseRR, 100);

    CALBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CALBuys.mBEAdditionalPips = BEAdditionalPips;
    CALBuys.mMaxPipsFromGreenLips = MaxPipsFromGreenLips;
    CALBuys.mMinBlueRedAlligatorGap = MinBlueRedAlligatorGap;
    CALBuys.mMinRedGreenAlligatorGap = MinRedGreenAlligatorGap;
    CALBuys.mMinWickLength = MinWickLength;

    CALBuys.AddTradingSession(TS);

    CALSells = new CrossAlligatorLips(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                      ErrorWriter);

    CALSells.SetPartialCSVRecordWriter(PartialWriter);
    CALSells.AddPartial(CloseRR, 100);

    CALSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CALSells.mBEAdditionalPips = BEAdditionalPips;
    CALSells.mMaxPipsFromGreenLips = MaxPipsFromGreenLips;
    CALSells.mMinBlueRedAlligatorGap = MinBlueRedAlligatorGap;
    CALSells.mMinRedGreenAlligatorGap = MinRedGreenAlligatorGap;
    CALSells.mMinWickLength = MinWickLength;

    CALSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CALBuys;
    delete CALSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CALBuys.Run();
    CALSells.Run();
}
