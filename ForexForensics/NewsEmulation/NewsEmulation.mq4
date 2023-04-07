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

#include <Wantanites\ForexForensics\NewsEmulation\NewsEmulation.mqh>

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;
List<int> *EconomicEventImpacts;

string Directory = "ForexForensics/NewsEmulation/";

CSVRecordWriter<ForexForensicsEntryTradeRecord> *EntryWriter = new CSVRecordWriter<ForexForensicsEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<ForexForensicsExitTradeRecord> *ExitWriter = new CSVRecordWriter<ForexForensicsExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<DefaultErrorRecord> *ErrorWriter = new CSVRecordWriter<DefaultErrorRecord>(Directory + "Errors/", "Errors.csv");

NewsEmulation *NE;

int OnInit()
{
    EconomicEventTitles = new List<string>();
    EconomicEventSymbols = new List<string>();
    EconomicEventImpacts = new List<int>();

    NE = new ForexForensics(EntryWriter, ExitWriter, ErrorWriter);
    NE.mEconomicEventTitles = EconomicEventTitles;
    NE.mEconomicEventSymbols = EconomicEventSymbols;
    NE.mEconomicEventImpacts = EconomicEventImpacts;

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

    delete NE;
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
    NE.Run();
    return (rates_total);
}