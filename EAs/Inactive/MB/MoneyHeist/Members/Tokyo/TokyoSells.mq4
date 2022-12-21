//+------------------------------------------------------------------+
//|                                                        Tokyo.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#include <SummitCapital/EAs/MoneyHeist/CrewMember.mqh>

// --- EA Inputs ---
string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 60;

double StopLossPaddingPips = 0;
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 10;

int SetupType = OP_SELL;

string StrategyName = "MoneyHeist/";
string EAName = "Tokyo/";
string SetupTypeName = "Sells/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

CrewMember *Tokyo;

int OnInit()
{
    // Should only be running on UJ on the 1 hour
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    Tokyo = new CrewMember(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    Tokyo.SetPartialCSVRecordWriter(PartialWriter);
    Tokyo.AddPartial(1000, 100);

    Tokyo.mAdditionalEntryPips = 60;
    Tokyo.mFixedStopLossPips = 60;
    Tokyo.mPipsToWaitBeforeBE = 60;
    Tokyo.mBEAdditionalPips = 12; // A tad bit more than spread

    Tokyo.AddTradingSession(1, 5, 23, 49);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete Tokyo;
    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    Tokyo.Run();
}
