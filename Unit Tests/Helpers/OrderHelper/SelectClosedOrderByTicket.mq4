//+------------------------------------------------------------------+
//|                                    SelectClosedOrderByTicket.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/SelectClosedOrderByTicket/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1unmo0PKUbeyC_V-Kg93JoKDXhPitaTSE/view?usp=sharin
IntUnitTest<DefaultUnitTestRecord> *SelectOpBuyClosedOrderNoErrorUnitTest;

// https://drive.google.com/file/d/18IY6nBWFrNvoWtqINi65EjA1BW82ljmz/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *SelectOpBuyStopClosedOrderNoErrorUnitTest;

// https://drive.google.com/file/d/1rbEm0jJPzWUKk2gU36AosmaWu-kiCDHs/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SelectOpBuyOpenOrderHasErrorUnitTest;

// https://drive.google.com/file/d/1oMfBxW72lRaE-M6evXib-rXtWdX1-Q6Z/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SelectOpBuyStopOpenOrderHasErrorUnitTest;

int OnInit()
{
    SelectOpBuyClosedOrderNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy No Error Unit Test", "Should Return No Errors When Selecting An OP BUY Closed Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, SelectOpBuyClosedOrderNoError);

    SelectOpBuyStopClosedOrderNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Stop No Error Unit Test", "Should Return No Errors When Selecting An OP BUYSTOP Closed Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, SelectOpBuyStopClosedOrderNoError);

    SelectOpBuyOpenOrderHasErrorUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Returns Error", "Should Return Order Is Open Error When Selecting An OP Buy Open Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_ORDER_IS_OPEN, SelectOpBuyOpenOrderHasError);

    SelectOpBuyStopOpenOrderHasErrorUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Stop Returns Error", "Should Return Order Is Open Error When Selecting An OP Buy Stop Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_ORDER_IS_OPEN, SelectOpBuyStopOpenOrderHasError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SelectOpBuyClosedOrderNoErrorUnitTest;
    delete SelectOpBuyStopClosedOrderNoErrorUnitTest;

    delete SelectOpBuyOpenOrderHasErrorUnitTest;
    delete SelectOpBuyStopOpenOrderHasErrorUnitTest;
}

void OnTick()
{
    SelectOpBuyClosedOrderNoErrorUnitTest.Assert();
    SelectOpBuyStopClosedOrderNoErrorUnitTest.Assert();

    SelectOpBuyOpenOrderHasErrorUnitTest.Assert();
    SelectOpBuyStopOpenOrderHasErrorUnitTest.Assert();
}

int SendOrder(int type, double entryPrice, double stopLoss)
{
    const double lots = 0.1;
    const int slippage = 0;
    const double takeProfit = 0.0;
    const string comment = NULL;
    const int magicNumber = 0;
    const datetime expiration = 0;
    const color col = clrNONE;

    return OrderSend(Symbol(), type, lots, entryPrice, slippage, stopLoss, takeProfit, comment, magicNumber, expiration, col);
}

int SelectOpBuyClosedOrderNoError(int &actual)
{
    int type = OP_BUY;
    double entryPrice = Ask;
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = SendOrder(type, entryPrice, stopLoss);
    if (ticket < 0)
    {
        return GetLastError();
    }

    if (!OrderClose(ticket, 0.1, Bid, 0, clrNONE))
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectClosedOrderByTicket(ticket, "Testing Selecing Closed Order No Error");
    return UnitTestConstants::UNIT_TEST_RAN;
}

int SelectOpBuyStopClosedOrderNoError(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = SendOrder(type, entryPrice, stopLoss);
    if (ticket < 0)
    {
        return GetLastError();
    }

    if (!OrderDelete(ticket, clrNONE))
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectClosedOrderByTicket(ticket, "Testing Selecing Closed Order No Error");
    return UnitTestConstants::UNIT_TEST_RAN;
}

int SelectOpBuyOpenOrderHasError(bool &actual)
{
    int type = OP_BUY;
    double entryPrice = Ask;
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = SendOrder(type, entryPrice, stopLoss);
    if (ticket < 0)
    {
        return GetLastError();
    }

    int error = OrderHelper::SelectClosedOrderByTicket(ticket, "Testing Selecting Open Order Returns Order Open Order");
    actual = (error == Errors::ERR_ORDER_IS_OPEN) || (error == Errors::ERR_ORDER_NOT_FOUND);

    OrderClose(ticket, 0.1, Bid, 0, clrNONE);

    return UnitTestConstants::UNIT_TEST_RAN;
}

int SelectOpBuyStopOpenOrderHasError(bool &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = SendOrder(type, entryPrice, stopLoss);
    if (ticket < 0)
    {
        return GetLastError();
    }

    int error = OrderHelper::SelectClosedOrderByTicket(ticket, "Testing Selecting Open Order Returns Order Open Order");
    actual = (error == Errors::ERR_ORDER_IS_OPEN) || (error == Errors::ERR_ORDER_NOT_FOUND);

    OrderDelete(ticket, clrNONE);

    return UnitTestConstants::UNIT_TEST_RAN;
}
