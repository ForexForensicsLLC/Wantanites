//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Inactive/MB/LiquidationEngulfing/LiquidationEngulfing.mqh>
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = ConstantValues::EmptyInt;
int MaxTradesPerDay = ConstantValues::EmptyInt;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("MBEngulfing/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("MBEngulfing/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("MBEngulfing/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("MBEngulfing/Errors/", "Errors.csv");

TradingSession *TS;

LiquidationEngulfing *BuyEA;
LiquidationEngulfing *SellEA;

double StopLossPaddingPips = 0.0;
double MaxSpreadPips = 3;
double CloseRR = 3;

int OnInit()
{
    TS = new TradingSession();

    BuyEA = new LiquidationEngulfing(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                     ErrorWriter, MBT);
    BuyEA.SetPartialCSVRecordWriter(PartialWriter);
    BuyEA.AddPartial(CloseRR, 100);
    BuyEA.AddTradingSession(TS);

    SellEA = new LiquidationEngulfing(-1, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                      ErrorWriter, MBT);
    SellEA.SetPartialCSVRecordWriter(PartialWriter);
    SellEA.AddPartial(CloseRR, 100);
    SellEA.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BuyEA;
    delete SellEA;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    BuyEA.Run();
    SellEA.Run();
}
