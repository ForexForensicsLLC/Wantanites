//+------------------------------------------------------------------+
//|                                          SelectOrderByTicket.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/SelectOpenOrderByTicket/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

IntUnitTest<DefaultUnitTestRecord> *NoErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *HasErrorUnitTest;

int OnInit()
{
    NoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Error Unit Test", "Should Return No Errors When Selecting An Open Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoError);

    HasErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Error Unit Test", "Should Return An Error When Selecting A Closed Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, HasError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NoErrorUnitTest;
    delete HasErrorUnitTest;
}

void OnTick()
{
    NoErrorUnitTest.Assert();
    HasErrorUnitTest.Assert(false);
}

int SendOrder()
{
    const double entryPrice = Ask + OrderHelper::PipsToRange(10);
    const double lots = 0.1;
    const int slippage = 0;
    const double stopLoss = 0.0;
    const double takeProfit = 0.0;
    const string comment = NULL;
    const int magicNumber = 0;
    const datetime expiration = 0;
    const color col = clrNONE;

    return OrderSend(Symbol(), OP_BUYSTOP, lots, entryPrice, slippage, stopLoss, takeProfit, comment, magicNumber, expiration, col);
}

int NoError(int &actual)
{
    int ticket = SendOrder();
    if (ticket < 0)
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");

    OrderDelete(ticket, clrNONE);

    return UnitTestConstants::UNIT_TEST_RAN;
}

int HasError(int &actual)
{
    int ticket = SendOrder();
    if (ticket < 0 || !OrderDelete(ticket, clrNONE))
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");
    return UnitTestConstants::UNIT_TEST_RAN;
}