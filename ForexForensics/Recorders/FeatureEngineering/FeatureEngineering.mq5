//+------------------------------------------------------------------+
//|                                           ForexForensics.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#property indicator_chart_window

#include <Wantanites\ForexForensics\Recorders\FeatureEngineering\FeatureEngineering.mqh>

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;
List<int> *EconomicEventImpacts;

string Directory = "ForexForensics/FeatureEngineering/";

CSVRecordWriter<FeatureEngineeringEntryTradeRecord> *EntryWriter = new CSVRecordWriter<FeatureEngineeringEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<FeatureEngineeringExitTradeRecord> *ExitWriter = new CSVRecordWriter<FeatureEngineeringExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<DefaultErrorRecord> *ErrorWriter = new CSVRecordWriter<DefaultErrorRecord>(Directory + "Errors/", "Errors.csv");

FeatureEngineering *FE;

int OnInit()
{
    EconomicEventTitles = new List<string>();
    EconomicEventSymbols = new List<string>();
    EconomicEventImpacts = new List<int>();

    FE = new FeatureEngineering(EntryWriter, ExitWriter, ErrorWriter);
    FE.mEconomicEventTitles = EconomicEventTitles;
    FE.mEconomicEventSymbols = EconomicEventSymbols;
    FE.mEconomicEventImpacts = EconomicEventImpacts;

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EconomicEventTitles;
    delete EconomicEventSymbols;
    delete EconomicEventImpacts;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;

    delete FE;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    FE.Run();
    return (rates_total);
}