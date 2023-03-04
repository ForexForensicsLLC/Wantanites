//+------------------------------------------------------------------+
//|                                          SelectOrderByTicket.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/SelectOpenOrderByTicket/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/118bTQ-v7Abb6mjjmTjCNj99p4Ip86q04/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *SelectOpBuyOpenOrderNoErrorUnitTest;

// https://drive.google.com/file/d/1fVyp3lk4RacsLyPVdOHdyVfGXC3AkKiY/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *SelectOpBuyStopOpenOrderNoErrorUnitTest;

// https://drive.google.com/file/d/1TZwl4gi1ktnRvUW40bPOTgH3IP__rFa7/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SelectOpBuyClosedOrderHasErrorUnitTest;

// https://drive.google.com/file/d/1jQhbcIMgW0fe0AydC2OlxsvAu-StvMUX/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SelectOpBuyStopClosedOrderHasErrorUnitTest;

int OnInit()
{
    SelectOpBuyOpenOrderNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Op Buy No Error", "Should Return No Errors When Selecting An OP Buy Open Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, SelectOpBuyOpenOrderNoError);

    SelectOpBuyStopOpenOrderNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Op Buy Stop No Error", "Should Return No Errors When Selecting An OP Buy Stop Open Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, SelectOpBuyStopOpenOrderNoError);

    SelectOpBuyClosedOrderHasErrorUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Has Error", "Should Return Order Is Closed Error When Selecting An OP Buy Closed Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::ORDER_IS_CLOSED, SelectOpBuyClosedOrderHasError);

    SelectOpBuyStopClosedOrderHasErrorUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Stop Has Error", "Should Return Order Is Closed Error When Selecting An OP Buy Stop Closed Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::ORDER_IS_CLOSED, SelectOpBuyStopClosedOrderHasError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SelectOpBuyOpenOrderNoErrorUnitTest;
    delete SelectOpBuyStopOpenOrderNoErrorUnitTest;

    delete SelectOpBuyClosedOrderHasErrorUnitTest;
    delete SelectOpBuyStopClosedOrderHasErrorUnitTest;
}

void OnTick()
{
    SelectOpBuyOpenOrderNoErrorUnitTest.Assert();
    SelectOpBuyStopOpenOrderNoErrorUnitTest.Assert();

    SelectOpBuyClosedOrderHasErrorUnitTest.Assert();
    SelectOpBuyStopClosedOrderHasErrorUnitTest.Assert();
}

int SendOrder(int type, double entryPrice, double stopLoss, string comment)
{
    const double lots = 0.1;
    const int slippage = 0;
    const double takeProfit = 0.0;
    const int magicNumber = 0;
    const datetime expiration = 0;
    const color col = clrNONE;

    return OrderSend(Symbol(), type, lots, entryPrice, slippage, stopLoss, takeProfit, comment, magicNumber, expiration, col);
}

int SelectOpBuyOpenOrderNoError(int &actual)
{
    int type = OP_BUY;
    double entryPrice = Ask;
    double stopLoss = Bid - OrderHelper::PipsToRange(200);

    int ticket = SendOrder(type, entryPrice, stopLoss, "Open OP Buy");
    if (ticket < 0)
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Selecting OP Buy Open Order No Errors");

    OrderClose(ticket, 0.1, Bid, 0, clrNONE);

    return Results::UNIT_TEST_RAN;
}

int SelectOpBuyStopOpenOrderNoError(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(200);
    double stopLoss = Bid - OrderHelper::PipsToRange(200);

    int ticket = SendOrder(type, entryPrice, stopLoss, "Open OP Buy Stop");
    if (ticket < 0)
    {
        return GetLastError();
    }

    actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Selecting OP Buy Stop Open Order No Errors");

    OrderDelete(ticket, clrNONE);

    return Results::UNIT_TEST_RAN;
}

int SelectOpBuyClosedOrderHasError(bool &actual)
{
    int type = OP_BUY;
    double entryPrice = Ask;
    double stopLoss = Bid - OrderHelper::PipsToRange(200);

    int ticket = SendOrder(type, entryPrice, stopLoss, "Closed OP Buy");
    if (ticket < 0)
    {
        return GetLastError();
    }

    if (!OrderClose(ticket, 0.1, Bid, 0, clrNONE))
    {
        return GetLastError();
    }

    int error = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Selecting OP Buy Closed Order Has Error");
    actual = (error == TerminalErrors::ORDER_IS_CLOSED) || (error == TerminalErrors::ORDER_NOT_FOUND);

    return Results::UNIT_TEST_RAN;
}

int SelectOpBuyStopClosedOrderHasError(bool &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(200);
    double stopLoss = Bid - OrderHelper::PipsToRange(200);

    int ticket = SendOrder(type, entryPrice, stopLoss, "Closed OP Buy Stop");
    if (ticket < 0)
    {
        return GetLastError();
    }

    if (!OrderDelete(ticket, clrNONE))
    {
        return GetLastError();
    }

    int error = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Selecting OP Buy Stop Closed Order Has Error");
    actual = (error == TerminalErrors::ORDER_IS_CLOSED) || (error == TerminalErrors::ORDER_NOT_FOUND);

    return Results::UNIT_TEST_RAN;
}