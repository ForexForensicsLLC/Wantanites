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
#include <Wantanites/EAs/Inactive/CandleStick/ImpulseReversal/ImpulseReversal.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "EU/";
string SetupTypeName = "ImpulseReversal/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceGridTracker *PGT;

ImpulseReversal *IRBuys;
ImpulseReversal *IRSells;

// EU
double MinPercentChange = 0.06;
double LotSize = 0.05;
double MaxSpreadPips = 0.8;
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

    PGT = new PriceGridTracker(15, 5);

    IRBuys = new ImpulseReversal(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, PGT);

    IRBuys.SetPartialCSVRecordWriter(PartialWriter);

    IRBuys.mMinPercentChange = MinPercentChange;
    IRBuys.mLotSize = LotSize;
    IRBuys.mEntryPaddingPips = EntryPaddingPips;
    IRBuys.mMinStopLossPips = MinStopLossPips;
    IRBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IRBuys.mBEAdditionalPips = BEAdditionalPips;

    IRBuys.AddTradingSession(14, 0, 17, 0);

    IRSells = new ImpulseReversal(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, PGT);
    IRSells.SetPartialCSVRecordWriter(PartialWriter);

    IRSells.mMinPercentChange = MinPercentChange;
    IRSells.mLotSize = LotSize;
    IRSells.mEntryPaddingPips = EntryPaddingPips;
    IRSells.mMinStopLossPips = MinStopLossPips;
    IRSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IRSells.mBEAdditionalPips = BEAdditionalPips;

    IRSells.AddTradingSession(14, 0, 17, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete IRBuys;
    delete IRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    IRBuys.Run();
    IRSells.Run();
}
