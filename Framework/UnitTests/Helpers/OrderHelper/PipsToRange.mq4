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
    delete nasUnitTest;
    delete eurusdUnitTest;
}

void OnTick()
{
    PipsToRange_EURUSD();
    PipsToRange_NASDAQ();
}

UnitTest<DefaultUnitTestRecord> *nasUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, "Nas100.csv", 1);
void PipsToRange_NASDAQ()
{
    if (Symbol() == "US100.cash")
    {
        nasUnitTest.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.1;

        nasUnitTest.assertEquals("Nas 100 Correct Pips To Range", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *eurusdUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, "EURUSD.csv", 1);
void PipsToRange_EURUSD()
{
    if (Symbol() == "EURUSD")
    {
        eurusdUnitTest.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.00001;

        eurusdUnitTest.assertEquals("EURUSD Correct Pips To Range", expected, actual);
    }
}
