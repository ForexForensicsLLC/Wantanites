//+------------------------------------------------------------------+
//|                                                   GetLotSize.mq4 |
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

const string Directory = "/UnitTests/Helpers/OrderHelper/GetLotSize/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1T9WUbc5H9WDCrDLi0J6EQELqk__hfyBo/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *CorrectMinLotSizeUnitTest;

int OnInit()
{
    CorrectMinLotSizeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Correct Min Lot Size", "Returns The Correct Min Lot Size",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectMinLotSizeExpected, CorrectMinLotSize);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CorrectMinLotSizeUnitTest;
}

void OnTick()
{
    CorrectMinLotSizeUnitTest.Assert();
}

int CorrectMinLotSizeExpected()
{
    return 100 * MarketInfo(Symbol(), MODE_MINLOT);
}

int CorrectMinLotSize(int &actual)
{
    double stopLossPips = 10000;
    double riskPercent = 0.1;

    actual = 100 * OrderHelper::GetLotSize(stopLossPips, riskPercent);
    return Results::UNIT_TEST_RAN;
}