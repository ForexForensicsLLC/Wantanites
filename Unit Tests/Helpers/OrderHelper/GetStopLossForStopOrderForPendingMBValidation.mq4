//+------------------------------------------------------------------+
//|                 GetStopLossForStopOrderOnPendingMBValidation.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/GetStopLossForStopOrderForPendingMBValidation/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

IntUnitTest<DefaultUnitTestRecord> *BullishMBNoErrorsUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBNoErrorsUnitTest;

IntUnitTest<DefaultUnitTestRecord> *BullishMBEmptyRetracementUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBEmptyRetracementUnitTest;

IntUnitTest<DefaultUnitTestRecord> *BullishMBCorrectEntryPriceUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBCorrectEntryPriceUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
}
