//+------------------------------------------------------------------+
//|                                                BullishKatara.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Katara/KataraSingleMB.mqh>
#include <SummitCapital/EAs/Katara/KataraDoubleMB.mqh>
#include <SummitCapital/EAs/Katara/KataraLiquidationMB.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxTradesPerStrategy = 1;
input double MaxSpreadPips = 3; // TODO: Put back to 0.3

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int SetupType = OP_BUY;

CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MultiTimeFrameEntryTradeRecord>("Katara/Bullish/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("Katara/Bullish/Partials/", "Partials.csv");
CSVRecordWriter<MultiTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<MultiTimeFrameExitTradeRecord>("Katara/Bullish/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("Katara/Bullish/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

KataraSingleMB *KSMB;
KataraDoubleMB *KDMB;
KataraLiquidationMB *KLMB;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    KSMB = new KataraSingleMB(SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT, ConfirmationMBT);
    KSMB.SetPartialCSVRecordWriter(PartialWriter);
    KSMB.AddPartial(13, 50);
    KSMB.AddPartial(30, 100);

    KDMB = new KataraDoubleMB(SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT, ConfirmationMBT);
    KDMB.SetPartialCSVRecordWriter(PartialWriter);
    KDMB.AddPartial(13, 50);
    KDMB.AddPartial(30, 100);

    KLMB = new KataraLiquidationMB(SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT, ConfirmationMBT);
    KLMB.SetPartialCSVRecordWriter(PartialWriter);
    KLMB.AddPartial(13, 50);
    KLMB.AddPartial(30, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete KSMB;
    delete KDMB;
    delete KLMB;

    delete SetupMBT;
    delete ConfirmationMBT;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    KSMB.Run();
    KDMB.Run();
    KLMB.Run();
}
