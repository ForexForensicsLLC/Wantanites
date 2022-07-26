//+------------------------------------------------------------------+
//|                                                  PipsToRange.mqh |
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

const string Directory = "/UnitTests/OrderHelper/PipsToRange/";

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete nasCorrectRangeUnitTest;
    delete eurusdCorrectRangeUnitTest;
}

void OnTick()
{
    NASDAQ_CorrectRange();
    EURUSD_CorrectRange();
}

UnitTest<DefaultUnitTestRecord> *nasCorrectRangeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, 1);
void NASDAQ_CorrectRange()
{
    if (Symbol() == "US100.cash")
    {
        nasCorrectRangeUnitTest.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.1;

        nasCorrectRangeUnitTest.assertEquals("Nas 100 Correct Pips To Range", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *eurusdCorrectRangeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, 1);
void EURUSD_CorrectRange()
{
    if (Symbol() == "EURUSD")
    {
        eurusdCorrectRangeUnitTest.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.00001;

        eurusdCorrectRangeUnitTest.assertEquals("EURUSD Correct Pips To Range", expected, actual);
    }
}
