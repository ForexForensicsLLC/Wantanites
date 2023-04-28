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

List<int> *LicensedAccountNumbers;
LicenseManager *LM;

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

bool IsLicensedAccount = false;
bool HasLicense = false;
datetime LastValidatedTime = 0;

int OnInit()
{
    if (!EAInitHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(4, 0, 23, 0);

    EconomicEventTitles = new List<string>();

    EconomicEventSymbols = new List<string>();
    EconomicEventSymbols.Add("USD");
    EconomicEventSymbols.Add("JPY");

    EconomicEventImpacts = new List<int>();
    EconomicEventImpacts.Add(ImpactEnum::HighImpact);

    TRB = new TimeRangeBreakout(2, 0, 4, 0);
    TRBBuys = new TestNewsTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutBuys, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                            MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBBuys.mEconomicEventTitles = EconomicEventTitles;
    TRBBuys.mEconomicEventSymbols = EconomicEventSymbols;
    TRBBuys.mEconomicEventImpacts = EconomicEventImpacts;
    TRBBuys.AddTradingSession(TS);

    TRBSells = new TestNewsTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutSells, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                             MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBSells.mEconomicEventTitles = EconomicEventTitles;
    TRBSells.mEconomicEventSymbols = EconomicEventSymbols;
    TRBSells.mEconomicEventImpacts = EconomicEventImpacts;
    TRBSells.AddTradingSession(TS);

    LicensedAccountNumbers = new List<int>();
    LicensedAccountNumbers.Add(1051598151);
    IsLicensedAccount = LicensedAccountNumbers.Contains(AccountInfoInteger(ACCOUNT_LOGIN));
    if (!IsLicensedAccount)
    {
        LM = new LicenseManager();
        LM.AddLicense(Licenses::SmartMoney);
    }

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete LM;

    delete TRB;

    delete EconomicEventTitles;
    delete EconomicEventSymbols;
    delete EconomicEventImpacts;

    delete TRBBuys;
    delete TRBSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;

    delete LicensedAccountNumbers;
}

void OnTick()
{
    if (IsLicensedAccount)
    {
        TRBBuys.Run();
        TRBSells.Run();
    }
    else if (HasLicense)
    {
        // Reset the license each day to make sure they still have it
        if (TimeCurrent() - LastValidatedTime > (60 * 60 * 24))
        {
            HasLicense = false;
            LastValidatedTime = 0;
        }

        TRBBuys.Run();
        TRBSells.Run();
    }
    else
    {
        HasLicense = EAInitHelper::HasLicenses(LM);
        if (HasLicense)
        {
            LastValidatedTime = TimeCurrent();
        }
    }
}