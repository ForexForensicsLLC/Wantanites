//+------------------------------------------------------------------+
//|                                                  RangeToPips.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/RangeToPips/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete nasCorrectRangeToPipsUnitTest;
    delete eurusdCorrectRangeToPipsUnitTest;
}

void OnTick()
{
    NASDAQ_CorrectRangeToPips();
    EURUSD_CorrectRangeToPips();
}

UnitTest<DefaultUnitTestRecord> *nasCorrectRangeToPipsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void NASDAQ_CorrectRangeToPips()
{
    if (Symbol() == "US100.cash")
    {
        nasCorrectRangeToPipsUnitTest.addTest(__FUNCTION__);

        const double range = 0.1;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1.0;

        nasCorrectRangeToPipsUnitTest.assertEquals("Nas100 Range to Pips", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *eurusdCorrectRangeToPipsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void EURUSD_CorrectRangeToPips()
{
    if (Symbol() == "EURUSD")
    {
        eurusdCorrectRangeToPipsUnitTest.addTest(__FUNCTION__);

        const double range = 0.00001;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1;

        eurusdCorrectRangeToPipsUnitTest.assertEquals("EURUSD Correct Range To Pips", expected, actual);
    }
}