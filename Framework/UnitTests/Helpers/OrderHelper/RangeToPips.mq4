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

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete nasUnitTest;
    delete eurusdUnitTest;
}

void OnTick()
{
}

UnitTest<DefaultUnitTestRecord> *nasUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, "Nas100.csv", 1);
void RangeToPips_NASDAQ()
{
    if (Symbol() == "US100.cash")
    {
        nasUnitTest.addTest(__FUNCTION__);

        const double range = 0.1;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1.0;

        nasUnitTest.assertEquals("Nas100 Range to Pips", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *eurusdUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, "EURUSD.csv", 1);
void RangeToPips_EURUSD()
{
    if (Symbol() == "EURUSD")
    {
        eurusdUnitTest.addTest(__FUNCTION__);

        const double range = 0.00001;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1;

        eurusdUnitTest.assertEquals("EURUSD Correct Range To Pips", expected, actual);
    }
}