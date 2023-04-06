//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/ForexForensics/Licensing/SmartMoney/SmartMoneyLicense.mqh>
#include <Wantanites/ForexForensics/Licensing/ForexForensics/ForexForensicsLicense.mqh>

#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/TimeRange/TimeRangeBreakout/TestNews/TestNewsTimeRangeBreakout.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeRangeBreakout/";
string EAName = "UJ/";
string SetupTypeName = "TestNewsContinuation/";
string Directory = StrategyName + EAName + SetupTypeName;

ObjectList<License> *Licenses;
ForexForensicsLicense *FFL;
SmartMoneyLicense *SML;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;
List<int> *EconomicEventImpacts;

TimeRangeBreakout *TRB;
TestNewsTimeRangeBreakout *TRBBuys;
TestNewsTimeRangeBreakout *TRBSells;

// UJ
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;

input int Value = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    Licenses = new ObjectList<License>();
    FFL = new ForexForensicsLicense();
    SML = new SmartMoneyLicense();

    Licenses.Add(FFL);
    Licenses.Add(SML);

    TS = new TradingSession();
    TS.AddHourMinuteSession(4, 0, 23, 0);

    EconomicEventTitles = new List<string>();

    EconomicEventSymbols = new List<string>();
    EconomicEventSymbols.Add("USD");
    EconomicEventSymbols.Add("JPY");

    EconomicEventImpacts = new List<int>();
    EconomicEventImpacts.Add(ImpactEnum::HighImpact);

    TRB = new TimeRangeBreakout(2, 0, 4, 0);
    TRBBuys = new TestNewsTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                            RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBBuys.mEconomicEventTitles = EconomicEventTitles;
    TRBBuys.mEconomicEventSymbols = EconomicEventSymbols;
    TRBBuys.mEconomicEventImpacts = EconomicEventImpacts;
    TRBBuys.AddTradingSession(TS);

    TRBSells = new TestNewsTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                             MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBSells.mEconomicEventTitles = EconomicEventTitles;
    TRBSells.mEconomicEventSymbols = EconomicEventSymbols;
    TRBSells.mEconomicEventImpacts = EconomicEventImpacts;
    TRBSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TRB;

    delete EconomicEventTitles;
    delete EconomicEventSymbols;
    delete EconomicEventImpacts;

    delete TRBBuys;
    delete TRBSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

bool HasLicense = false;
void OnTick()
{
    if (HasLicense)
    {
        TRBBuys.Run();
        TRBSells.Run();
    }
    else
    {
        HasLicense = EAHelper::HasLicense(Licenses);
    }
}
