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
#include <Wantanites/EAs/Inactive/News/ClearMBs/NewsClearMBs.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "News/";
string EAName = "UJ/";
string SetupTypeName = "ClearMBs/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");

TradingSession *TS;

List<string> *NewsTitles;
List<string> *NewsSymbols;

// -- MBTracker Inputs
MBTracker *MBT;
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

NewsClearMBs *EBNHBuys;
NewsClearMBs *EBNHSells;

double MaxSpreadPips = 3;
double StopLossPaddingPips = 13;
double PipsToWaitBeforeBE = 10;
double BEAdditionalPips = 0.5;
int ClearHour = 14;
int ClearMinute = 0;
int CloseHour = 22;
int CloseMinute = 59;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                        CalculateOnTick);

    TS = new TradingSession();
    TS.AddHourMinuteSession(14, 30, 17, 30);

    NewsTitles = new List<string>();
    NewsTitles.Add("BOJ Policy Rate");
    NewsTitles.Add("Core PPI m/m");
    NewsTitles.Add("Non-Farm Employment Change");
    NewsTitles.Add("Empire State Manufacturing Index");
    NewsTitles.Add("Average Hourly Earnings m/m");
    NewsTitles.Add("FOMC Economic Projections");
    NewsTitles.Add("Treasury Currency Report");
    NewsTitles.Add("BOJ Outlook Report");
    NewsTitles.Add("Flash Services PMI");
    NewsTitles.Add("FOMC Press Conference");
    NewsTitles.Add("Federal Funds Rate");
    NewsTitles.Add("SNB Policy Rate");
    NewsTitles.Add("FOMC Statement");
    NewsTitles.Add("Unemployment Rate");
    NewsTitles.Add("CPI m/m");
    NewsTitles.Add("Core CPI m/m");
    NewsTitles.Add("SNB Press Conference");
    NewsTitles.Add("Monetary Policy Statement");
    NewsTitles.Add("JOLTS Job Openings");
    NewsTitles.Add("Building Permits m/m");
    NewsTitles.Add("BOJ Gov-Designate Ueda Speaks");
    NewsTitles.Add("Median CPI y/y");
    NewsTitles.Add("Trimmed CPI y/y");
    NewsTitles.Add("Employment Change");
    NewsTitles.Add("ISM Manufacturing PMI");
    NewsTitles.Add("Italian Parliamentary Election");
    NewsTitles.Add("BOJ Gov Shirakawa Speaks");
    NewsTitles.Add("FOMC Meeting Minutes");
    NewsTitles.Add("ISM Services PMI");
    NewsTitles.Add("Advance GDP q/q");
    NewsTitles.Add("Gov Board Member Zurbrugg Speaks");
    NewsTitles.Add("Core PCE Price Index m/m");
    NewsTitles.Add("Overnight Call Rate");
    NewsTitles.Add("Spanish Services PMI");
    NewsTitles.Add("Prelim ANZ Business Confidence");
    NewsTitles.Add("Fed Chair Yellen Testifies");
    NewsTitles.Add("PPI m/m");
    NewsTitles.Add("Core Retail Sales m/m");
    NewsTitles.Add("CPI y/y");
    NewsTitles.Add("Manufacturing Sales m/m");
    NewsTitles.Add("ADP Non-Farm Employment Change");
    NewsTitles.Add("Final GDP q/q");
    NewsTitles.Add("Fed Monetary Policy Report");
    NewsTitles.Add("Fed Chair Yellen Speaks");
    NewsTitles.Add("Philly Fed Manufacturing Index");
    NewsTitles.Add("Mid-Year Economic and Fiscal Outlook");
    NewsTitles.Add("Unemployment Claims");
    NewsTitles.Add("ECB Press Conference");
    NewsTitles.Add("Crude Oil Inventories");
    NewsTitles.Add("Prelim UoM Consumer Sentiment");
    NewsTitles.Add("BOC Gov Carney Speaks");
    NewsTitles.Add("Fed Chair Powell Testifies");
    NewsTitles.Add("Libor Rate");
    NewsTitles.Add("GDT Price Index");
    NewsTitles.Add("Flash Manufacturing PMI");
    NewsTitles.Add("FOMC Member Lacker Speaks");

    NewsSymbols = new List<string>();
    NewsSymbols.Add("USD");
    NewsSymbols.Add("JPY");

    EBNHBuys = new NewsClearMBs(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);

    EBNHBuys.mNewsTitles = NewsTitles;
    EBNHBuys.mNewsSymbols = NewsSymbols;
    EBNHBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHBuys.mBEAdditionalPips = BEAdditionalPips;
    EBNHBuys.mClearHour = ClearHour;
    EBNHBuys.mClearMinute = ClearMinute;
    EBNHBuys.mCloseHour = CloseHour;
    EBNHBuys.mCloseMinute = CloseMinute;
    EBNHBuys.AddTradingSession(TS);
    EBNHBuys.AddPartial(1.5, 100);
    EBNHBuys.SetPartialCSVRecordWriter(PartialWriter);

    EBNHSells = new NewsClearMBs(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                 MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);

    EBNHSells.mNewsTitles = NewsTitles;
    EBNHSells.mNewsSymbols = NewsSymbols;
    EBNHSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHSells.mBEAdditionalPips = BEAdditionalPips;
    EBNHSells.mClearHour = ClearHour;
    EBNHSells.mClearMinute = ClearMinute;
    EBNHSells.mCloseHour = CloseHour;
    EBNHSells.mCloseMinute = CloseMinute;
    EBNHSells.AddTradingSession(TS);
    EBNHSells.AddPartial(1.5, 100);
    EBNHSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete NewsSymbols;

    delete EBNHBuys;
    delete EBNHSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
    delete PartialWriter;
}

void OnTick()
{
    EBNHBuys.Run();
    EBNHSells.Run();
}
