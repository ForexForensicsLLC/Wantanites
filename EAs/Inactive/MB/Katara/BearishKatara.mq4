//+------------------------------------------------------------------+
//|                                                BearishKatara.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/EAs/Katara/KataraSingleMBDoji.mqh>

#include <WantaCapital/EAs/Katara/KataraSingleMB.mqh>
#include <WantaCapital/EAs/Katara/KataraDoubleMB.mqh>
#include <WantaCapital/EAs/Katara/KataraLiquidationMB.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0.1;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int SetupType = OP_SELL;

CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MultiTimeFrameEntryTradeRecord>("Katara/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("Katara/Partials/", "Partials.csv");
CSVRecordWriter<MultiTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<MultiTimeFrameExitTradeRecord>("Katara/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("Katara/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

KataraSingleMB *KSMB;
KataraDoubleMB *KDMB;
KataraLiquidationMB *KLMB;

KataraSingleMBDoji *KSMBD;

LiquidationSetupTracker *LiquidationSetup;
LiquidationSetupTracker *LiquidationConfirmation;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    LiquidationSetup = new LiquidationSetupTracker(SetupType, SetupMBT);
    LiquidationConfirmation = new LiquidationSetupTracker(SetupType, ConfirmationMBT);

    KSMB = new KataraSingleMB(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                              ErrorWriter, SetupMBT, ConfirmationMBT, LiquidationSetup);
    KSMB.SetPartialCSVRecordWriter(PartialWriter);
    KSMB.AddPartial(13, 50);
    KSMB.AddPartial(30, 100);

    KSMBD = new KataraSingleMBDoji(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT, ConfirmationMBT, LiquidationSetup);
    KSMBD.SetPartialCSVRecordWriter(PartialWriter);
    KSMBD.AddPartial(10000, 100);

    KDMB = new KataraDoubleMB(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                              ErrorWriter, SetupMBT, ConfirmationMBT, LiquidationSetup);
    KDMB.SetPartialCSVRecordWriter(PartialWriter);
    KDMB.AddPartial(13, 50);
    KDMB.AddPartial(30, 100);

    KLMB = new KataraLiquidationMB(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT, ConfirmationMBT, LiquidationSetup, LiquidationConfirmation);
    KLMB.SetPartialCSVRecordWriter(PartialWriter);
    KLMB.AddPartial(13, 50);
    KLMB.AddPartial(30, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete KSMBD;

    delete KSMB;
    delete KDMB;
    delete KLMB;

    delete SetupMBT;
    delete ConfirmationMBT;

    delete LiquidationSetup;
    delete LiquidationConfirmation;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    KSMBD.Run();

    // KSMB.Run();
    // KDMB.Run();
    // KLMB.Run();
}
