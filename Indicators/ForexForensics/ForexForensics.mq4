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

#include <Wantanites\EAs\Inactive\ForexForensics\ForexForensics.mqh>

// EA that is always within its trading session and in the setup function just checks for new tickets and add thems
// the rest of the framework should handle closing

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;
List<int> *EconomicEventImpacts;

string Directory = "ForexForensics/Test/";

CSVRecordWriter<ForexForensicsEntryTradeRecord> *EntryWriter = new CSVRecordWriter<ForexForensicsEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<ForexForensicsExitTradeRecord> *ExitWriter = new CSVRecordWriter<ForexForensicsExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<DefaultErrorRecord> *ErrorWriter = new CSVRecordWriter<DefaultErrorRecord>(Directory + "Errors/", "Errors.csv");

ForexForensics *FF;

int OnInit()
{
    EconomicEventTitles = new List<string>();

    EconomicEventSymbols = new List<string>();
    // EconomicEventSymbols.Add("USD");
    // EconomicEventSymbols.Add("JPY");

    EconomicEventImpacts = new List<int>();
    EconomicEventImpacts.Add(ImpactEnum::HighImpact);

    FF = new ForexForensics(EntryWriter, ExitWriter, ErrorWriter);
    FF.mEconomicEventTitles = EconomicEventTitles;
    FF.mEconomicEventSymbols = EconomicEventSymbols;
    FF.mEconomicEventImpacts = EconomicEventImpacts;

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

    delete FF;
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
    FF.Run();
    return (rates_total);
}