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

#include <Wantanites\ForexForensics\Recorders\InDepthAnalysis\InDepthAnalysis.mqh>

List<string> *EconomicEventTitles;
List<string> *EconomicEventSymbols;
List<int> *EconomicEventImpacts;

string Directory = "ForexForensics/TylerWanta/InDepthAnalysis/";

CSVRecordWriter<ForexForensicsEntryTradeRecord> *EntryWriter = new CSVRecordWriter<ForexForensicsEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<ForexForensicsExitTradeRecord> *ExitWriter = new CSVRecordWriter<ForexForensicsExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<DefaultErrorRecord> *ErrorWriter = new CSVRecordWriter<DefaultErrorRecord>(Directory + "Errors/", "Errors.csv");

InDepthAnalysis *IDA;

int OnInit()
{
    EconomicEventTitles = new List<string>();
    EconomicEventSymbols = new List<string>();
    EconomicEventImpacts = new List<int>();

    IDA = new InDepthAnalysis(EntryWriter, ExitWriter, ErrorWriter);
    IDA.mEconomicEventTitles = EconomicEventTitles;
    IDA.mEconomicEventSymbols = EconomicEventSymbols;
    IDA.mEconomicEventImpacts = EconomicEventImpacts;

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

    delete IDA;
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
    IDA.Run();
    return (rates_total);
}