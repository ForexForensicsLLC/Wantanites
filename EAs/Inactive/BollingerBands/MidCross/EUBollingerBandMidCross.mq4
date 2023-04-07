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
#include <Wantanites/EAs/Inactive/BollingerBands/MidCross/BollingerBandMidCross.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 1;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "BollingerBands/";
string EAName = "EU/";
string SetupTypeName = "MidCross/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;

MidCross *MCBuys;
MidCross *MCSells;

// EU
double MaxSpreadPips = 3;
double StopLossPaddingPips = 5;
double MinOrderPips = 5;
double TakeProfitPips = 10;
double SurviveTargetPips = 5;
double LotsPerBalancePeriod = 10000;
double LotsPerBalanceLotIncrement = 1;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(16, 30, 19, 0);

    EconomicEventTitles = new List<string>();

    EconomicEventSymbols = new List<string>();
    EconomicEventSymbols.Add("USD");

    MCBuys = new MidCross(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter);

    MCBuys.mEconomicEventTitles = EconomicEventTitles;
    MCBuys.mEconomicEventSymbols = EconomicEventSymbols;
    MCBuys.mMinOrderPips = MinOrderPips;
    MCBuys.mTakeProfitPips = TakeProfitPips;
    MCBuys.mSurviveTargetPips = SurviveTargetPips;
    MCBuys.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MCBuys.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    MCBuys.SetPartialCSVRecordWriter(PartialWriter);
    MCBuys.AddPartial(1, 100);
    MCBuys.AddTradingSession(TS);

    MCSells = new MidCross(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter);

    MCSells.mEconomicEventTitles = EconomicEventTitles;
    MCSells.mEconomicEventSymbols = EconomicEventSymbols;
    MCSells.mMinOrderPips = MinOrderPips;
    MCSells.mTakeProfitPips = TakeProfitPips;
    MCSells.mSurviveTargetPips = SurviveTargetPips;
    MCSells.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MCSells.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    MCSells.SetPartialCSVRecordWriter(PartialWriter);
    MCSells.AddPartial(1, 100);
    MCSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EconomicEventTitles;
    delete EconomicEventSymbols;

    delete MCBuys;
    delete MCSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MCBuys.Run();
    MCSells.Run();
}
