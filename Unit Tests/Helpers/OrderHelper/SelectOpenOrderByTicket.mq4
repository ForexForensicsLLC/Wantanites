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
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/SelectOpenOrderByTicket/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete noErrorUnitTest;
    delete hasErrorUnitTest;
}

void OnTick()
{
    NoError();
    HasError();
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

UnitTest<DefaultUnitTestRecord> *noErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void NoError()
{
    int ticket = SendOrder();
    if (ticket < 0)
    {
        return;
    }

    noErrorUnitTest.addTest(__FUNCTION__);

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");

    noErrorUnitTest.assertEquals("Select Order By Ticket No Errors", expected, actual);

    OrderDelete(ticket, clrNONE);
}

UnitTest<DefaultUnitTestRecord> *hasErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void HasError()
{
    int ticket = SendOrder();
    if (ticket < 0 || !OrderDelete(ticket, clrNONE))
    {
        return;
    }

    hasErrorUnitTest.addTest(__FUNCTION__);

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");

    if (actual > 1)
    {
        expected = actual;
    }

    hasErrorUnitTest.assertEquals("Select Order By Ticket When No Current Orders Errors", expected, actual);
}