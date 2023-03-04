//+------------------------------------------------------------------+
//|                                                   MBRecorder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Trackers\LiquidationSetupTracker.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

#include <Wantanites\Framework\Helpers\ScreenShotHelper.mqh>
#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\Helpers\OrderHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 10;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input double MaxSpreadPips = 10;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 1;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int SetupType = OP_BUY;

string ConsecutiveMBDir = "MBRecorder/MBsWithoutWickBreaks/ConsecutiveMBs/";
string HeldMBDir = "MBRecorder/MBsWithoutWickBreaks/MBHeld/";
string LiquidationHoldsDir = "MBRecorder/MBsWithoutWickBreaks/LiquidationHolds/";
string PipsRanAfterDir = "MBRecorder/MBsWithoutWickBreaks/PipsRanAfter/";
string MBDimensionsDir = "MBRecorder/MBsWithoutWickBreaks/MBDimensions/";

// CSVRecordWriter<SingleTimeFrameErrorRecord> *ConsecutiveMBsWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(ConsecutiveMBDir, "ConsecutiveMBs.csv");
// CSVRecordWriter<SingleTimeFrameErrorRecord> *MBHeldWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(HeldMBDir, "MBHeld.csv");
// CSVRecordWriter<SingleTimeFrameErrorRecord> *MBHeldWithZoneWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(HeldMBDir, "MBHeldWithZone.csv");
// CSVRecordWriter<SingleTimeFrameErrorRecord> *LiquidationHolds = new CSVRecordWriter<SingleTimeFrameErrorRecord>(LiquidationHoldsDir, "LiqHolds.csv");
// CSVRecordWriter<SingleTimeFrameErrorRecord> *PipsRanAfter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(PipsRanAfterDir, "PipsRanAfter.csv");
// CSVRecordWriter<SingleTimeFrameErrorRecord> *ImpulseValHeld = new CSVRecordWriter<SingleTimeFrameErrorRecord>(HeldMBDir, "ImpulseValHeld.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *MBDimemsionsWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(MBDimensionsDir, "MBDimensions.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

LiquidationSetupTracker *BullishLiquidationSetup;
LiquidationSetupTracker *BearishLiquidationSetup;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    // ConfirmationMBT = new MBTracker(Symbol(), 1, 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    // BullishLiquidationSetup = new LiquidationSetupTracker(OP_BUY, SetupMBT);
    // BearishLiquidationSetup = new LiquidationSetupTracker(OP_SELL, SetupMBT);

    // LiquidationConfirmation = new LiquidationSetupTracker(SetupType, ConfirmationMBT);

    return (INIT_SUCCEEDED);
}

int MBsCounted = 0;
int LiquidationCount = 0;

void OnDeinit(const int reason)
{
    SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();
    record.AdditionalInformation = "Total MBs: " + SetupMBT.MBsCreated() + " MBs Counted: " + MBsCounted;

    // ConsecutiveMBsWriter.WriteRecord(record);
    // MBHeldWriter.WriteRecord(record);
    // MBHeldWithZoneWriter.WriteRecord(record);
    // LiquidationHolds.WriteRecord(record);
    MBDimemsionsWriter.WriteRecord(record);

    // SingleTimeFrameErrorRecord *record2 = new SingleTimeFrameErrorRecord();
    // record2.AdditionalInformation = "Liquidation Count: " + LiquidationCount;

    // LiquidationHolds.WriteRecord(record2);

    // RecordPipsRan();
    // CountHasImpulseValidationMBs();

    delete record;
    // delete record2;

    // delete MBR;

    delete SetupMBT;
    delete ConfirmationMBT;

    delete BullishLiquidationSetup;
    delete BearishLiquidationSetup;

    // delete ConsecutiveMBsWriter;
    // delete MBHeldWriter;

    delete MBDimemsionsWriter;
}

int CurrentMBs = 0;
bool BullishHadLiquidationSetup = false;
bool BearishHadLiquidationSetup = false;

int but1;
int but2;
int but3;

int bet1;
int bet2;
int bet3;

int MBCount = 0;
void OnTick()
{
    SetupMBT.DrawNMostRecentMBs(-1);
    SetupMBT.DrawZonesForNMostRecentMBs(-1);

    bool duringTime = Hour() >= 16 && Hour() < 23;
    if (SetupMBT.MBsCreated() > CurrentMBs)
    {
        // MBsCounted += 1;
        // if (SetupMBT.NthMostRecentMBIsOpposite(0))
        // {
        //     int consecutiveMBs = SetupMBT.NumberOfConsecutiveMBsBeforeNthMostRecent(0);
        //     SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

        //     record.Symbol = Symbol();
        //     record.MagicNumber = Period();
        //     record.ErrorTime = TimeCurrent();
        //     record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(ConsecutiveMBDir);
        //     record.Error = consecutiveMBs;

        //     ConsecutiveMBsWriter.WriteRecord(record);
        //     delete record;
        // }
        // else
        // {
        //     MBCount += 1;
        //     SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

        //     record.Symbol = Symbol();
        //     record.MagicNumber = Period();
        //     record.ErrorTime = TimeCurrent();
        //     record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(HeldMBDir);
        //     record.AdditionalInformation = MBCount;

        //     MBHeldWriter.WriteRecord(record);

        //     MBState *tempMBState;
        //     SetupMBT.GetNthMostRecentMB(1, tempMBState);

        //     if (tempMBState.ClosestValidZoneIsHolding(tempMBState.EndIndex()))
        //     {
        //         ZoneState *tempZoneState;
        //         tempMBState.GetDeepestHoldingZone(tempZoneState);
        //         record.AdditionalInformation += " " + tempZoneState.Number();
        //         MBHeldWithZoneWriter.WriteRecord(record);

        //         if (tempMBState.HasImpulseValidation())
        //         {
        //             ImpulseValHeld.WriteRecord(record);
        //         }
        //     }

        //     delete record;
        // }

        // CheckLiquidationSetup(OP_BUY, BullishHadLiquidationSetup, but1, but2, but3, BullishLiquidationSetup);
        // CheckLiquidationSetup(OP_SELL, BearishHadLiquidationSetup, bet1, bet2, bet3, BearishLiquidationSetup);

        CurrentMBs = SetupMBT.MBsCreated();

        MBState *previousMBState;
        if (!SetupMBT.GetNthMostRecentMB(1, previousMBState))
        {
            return;
        }

        MBState *tempMBState;
        if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (previousMBState.Type() != tempMBState.Type())
        {
            return;
        }

        int minCandles = 7;
        int maxPips = 1000;
        int minPipsPerCandle = 70;
        int minHeightPips = 250;

        double currentMBPercentIntoPrevious = 0.5;

        double previousMBHeight = iHigh(Symbol(), Period(), previousMBState.HighIndex()) - iLow(Symbol(), Period(), previousMBState.LowIndex());
        if (OrderHelper::RangeToPips(previousMBHeight) < minHeightPips || OrderHelper::RangeToPips(previousMBHeight) > maxPips)
        {
            return;
        }

        double pushedInto = -1.0;
        if (previousMBState.Type() == OP_BUY)
        {
            pushedInto = (iHigh(Symbol(), Period(), previousMBState.HighIndex()) - iLow(Symbol(), Period(), tempMBState.LowIndex())) / previousMBHeight;
            if (pushedInto < currentMBPercentIntoPrevious)
            {
                return;
            }
        }
        else if (previousMBState.Type() == OP_SELL)
        {
            pushedInto = (iHigh(Symbol(), Period(), tempMBState.HighIndex()) - iLow(Symbol(), Period(), previousMBState.LowIndex())) / previousMBHeight;
            if (pushedInto < currentMBPercentIntoPrevious)
            {
                return;
            }
        }

        double currentMBWidth = tempMBState.StartIndex() - tempMBState.EndIndex();
        double currentMBHeightPips = NormalizeDouble(
            OrderHelper::RangeToPips(
                iHigh(Symbol(), Period(), tempMBState.HighIndex()) - iLow(Symbol(), Period(), tempMBState.LowIndex())),
            Digits);

        double pipsPerCandle = NormalizeDouble(currentMBHeightPips / currentMBWidth, Digits);

        // if (width < minCandles || heightPips > maxPips || pipsPerCandle < minPipsPerCandle)
        // {
        //     return;
        // }

        SingleTimeFrameErrorRecord *dimensionsRecord = new SingleTimeFrameErrorRecord();
        dimensionsRecord.Symbol = Symbol();
        dimensionsRecord.MagicNumber = Period();
        dimensionsRecord.ErrorTime = TimeCurrent();
        dimensionsRecord.ErrorImage = ScreenShotHelper::TryTakeScreenShot(MBDimensionsDir);
        dimensionsRecord.AdditionalInformation = currentMBWidth + " " +
                                                 currentMBHeightPips + " " +
                                                 pipsPerCandle + " " +
                                                 OrderHelper::RangeToPips(previousMBHeight) + " " +
                                                 pushedInto;
        MBDimemsionsWriter.WriteRecord(dimensionsRecord);
        MBsCounted += 1;

        delete dimensionsRecord;
    }
    // else if (!duringTime)
    // {
    //     MBCount = 0;
    // }
}

// void CheckLiquidationSetup(int liqudiationSetupType, bool &hadLiquidationSetup, int &t1, int &t2, int &t3, LiquidationSetupTracker *&lst)
// {
//     if (hadLiquidationSetup && !lst.HasSetup(t3, t3, t3))
//     {
//         MBState *tempMBState;
//         SetupMBT.GetNthMostRecentMB(0, tempMBState);

//         MBState *firstMB;
//         SetupMBT.GetMB(t1, firstMB);

//         bool holding = false;
//         SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(t1, t2, SetupMBT, holding);

//         if (tempMBState.Type() == liqudiationSetupType && holding)
//         {
//             SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

//             record.Symbol = Symbol();
//             record.MagicNumber = Period();
//             record.ErrorTime = TimeCurrent();
//             record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(LiquidationHoldsDir);
//             record.AdditionalInformation = "Held";

//             LiquidationHolds.WriteRecord(record);
//             delete record;
//         }

//         t1 = EMPTY;
//         t2 = EMPTY;
//         t3 = EMPTY;
//         hadLiquidationSetup = false;
//     }
//     else if (lst.HasSetup(t1, t2, t3) && !hadLiquidationSetup)
//     {
//         LiquidationCount += 1;
//         hadLiquidationSetup = true;
//     }
// }

// void RecordPipsRan()
// {
//     for (int i = 0; i < SetupMBT.MBsCreated(); i++)
//     {
//         MBState *tempMBState;
//         if (!SetupMBT.GetMB(i, tempMBState))
//         {
//             continue;
//         }

//         bool foundBrokeIndex = false;
//         double pipsRan = 0.0;

//         for (int j = tempMBState.EndIndex(); j >= 0; j--)
//         {
//             if (tempMBState.Type() == OP_BUY)
//             {
//                 if (iLow(Symbol(), Period(), j) < iLow(Symbol(), Period(), tempMBState.LowIndex()))
//                 {
//                     double ran;
//                     if (MQLHelper::GetHighestHighBetween(Symbol(), Period(), tempMBState.EndIndex(), j, true, ran))
//                     {
//                         foundBrokeIndex = true;
//                         pipsRan = OrderHelper::RangeToPips(ran - iHigh(Symbol(), Period(), tempMBState.HighIndex()));
//                     }

//                     break;
//                 }
//             }
//             else if (tempMBState.Type() == OP_SELL)
//             {
//                 if (iHigh(Symbol(), Period(), j) > iHigh(Symbol(), Period(), tempMBState.HighIndex()))
//                 {
//                     double ran;
//                     if (MQLHelper::GetLowestLowBetween(Symbol(), Period(), tempMBState.EndIndex(), j, true, ran))
//                     {
//                         foundBrokeIndex = true;
//                         pipsRan = OrderHelper::RangeToPips(iLow(Symbol(), Period(), tempMBState.LowIndex()) - ran);
//                     }

//                     break;
//                 }
//             }
//         }

//         if (foundBrokeIndex)
//         {
//             SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

//             double mbWidth = OrderHelper::RangeToPips(
//                 NormalizeDouble(
//                     MathAbs(
//                         iHigh(Symbol(), Period(), tempMBState.HighIndex()) - iLow(Symbol(), Period(), tempMBState.LowIndex())),
//                     Digits));

//             record.Symbol = Symbol();
//             record.MagicNumber = Period();
//             record.ErrorTime = iTime(Symbol(), Period(), tempMBState.EndIndex());
//             record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(PipsRanAfterDir, record.ErrorTime);
//             record.AdditionalInformation = pipsRan + " " + mbWidth;

//             PipsRanAfter.WriteRecord(record);
//             delete record;
//         }
//     }
// }

// void CountHasImpulseValidationMBs()
// {
//     int impulseValCount = 0;
//     for (int i = 0; i < SetupMBT.CurrentMBs() - 1; i++)
//     {
//         MBState *tempMBState;
//         if (!SetupMBT.GetNthMostRecentMB(i, tempMBState))
//         {
//             continue;
//         }

//         if (tempMBState.HasImpulseValidation())
//         {
//             SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

//             record.Symbol = Symbol();
//             record.MagicNumber = Period();
//             record.ErrorTime = TimeCurrent();
//             record.AdditionalInformation = "Total Impulse Validation MBs: " + impulseValCount;

//             ImpulseValHeld.WriteRecord(record);
//             delete record;
//             impulseValCount += 1;
//         }
//     }

//     SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();

//     record.Symbol = Symbol();
//     record.MagicNumber = Period();
//     record.ErrorTime = TimeCurrent();
//     record.AdditionalInformation = "Total Impulse Validation MBs: " + impulseValCount;

//     ImpulseValHeld.WriteRecord(record);
//     delete record;
// }