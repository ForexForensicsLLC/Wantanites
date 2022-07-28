//+------------------------------------------------------------------+
//|                                               PlaceStopOrder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Errors.mqh>

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/PlaceStopOrder/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

IntUnitTest<DefaultUnitTestRecord> *BuyStopNoErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *SellStopNoErrorUnitTest;

IntUnitTest<DefaultUnitTestRecord> *OpBuyWrongOrderTypeUnitTest;
IntUnitTest<DefaultUnitTestRecord> *OpSellWrongOrderTypeUnitTest;
IntUnitTest<DefaultUnitTestRecord> *OpBuyLimitWrongOrderTypeUnitTest;
IntUnitTest<DefaultUnitTestRecord> *OpSellLimitWrongOrderTypeUnitTest;

IntUnitTest<DefaultUnitTestRecord> *StopLossAboveBuyStopEntryErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *StopLossBelowSellStopEntryErrorUnitTest;

int OnInit()
{
    BuyStopNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Buy Stop No Errrors", "No Errors When Placing Buy Stop Orders",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BuyStopNoError);

    SellStopNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Sell Stop No Errors", "No Errors When Placing Sell Stop ORders",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, SellStopNoError);

    OpBuyWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Wrong Order Type", "Returns Error When Placing OP Buy",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_WRONG_ORDER_TYPE, OpBuyWrongOrderType);

    OpSellWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Wrong Order Type", "Returns Error When Placing OP Sell",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_WRONG_ORDER_TYPE, OpSellWrongOrderType);

    OpBuyLimitWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Limit Wrong Order Type", "Returns Error When Placing OP Buy Limit",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_WRONG_ORDER_TYPE, OpBuyLimitWrongOrderType);

    OpSellLimitWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Limit Wrong Order Type", "Returns Error When Placing OP Sell Limit",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_WRONG_ORDER_TYPE, OpSellLimitWrongOrderType);

    StopLossAboveBuyStopEntryErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Stop Loss Above Buy Stop Entry Error", "Returns Error When Stop Loss is Above Buy Stop Entry",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_STOPLOSS_ABOVE_ENTRY, StopLossAboveBuyStopEntryError);

    StopLossBelowSellStopEntryErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Stop Loss Below Sell Stop Entry Error", "Returns Error When Stop Loss Is Below Sell Stop Entry",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_STOPLOSS_ABOVE_ENTRY, StopLossBelowSellStopEntryError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete BuyStopNoErrorUnitTest;
    delete SellStopNoErrorUnitTest;

    delete OpBuyWrongOrderTypeUnitTest;
    delete OpSellWrongOrderTypeUnitTest;
    delete OpBuyLimitWrongOrderTypeUnitTest;
    delete OpSellLimitWrongOrderTypeUnitTest;

    delete StopLossAboveBuyStopEntryErrorUnitTest;
    delete StopLossBelowSellStopEntryErrorUnitTest;
}

void OnTick()
{
    BuyStopNoErrorUnitTest.Assert();
    SellStopNoErrorUnitTest.Assert();

    OpBuyWrongOrderTypeUnitTest.Assert();
    OpSellWrongOrderTypeUnitTest.Assert();
    OpBuyLimitWrongOrderTypeUnitTest.Assert();
    OpSellLimitWrongOrderTypeUnitTest.Assert();

    StopLossAboveBuyStopEntryErrorUnitTest.Assert();
    StopLossBelowSellStopEntryErrorUnitTest.Assert();
}

int PlaceStopOrder(int type, double entryPrice, double stopLoss, out int &ticket)
{
    ticket = -1;
    const double lots = 0.1;
    const double takeProfit = 0.0;
    const int magicNumber = 0;

    return OrderHelper::PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, magicNumber, ticket);
}

int PlaceStopOrder(int type, double entryPrice, out int &ticket)
{
    return PlaceStopOrder(ticket, entryPrice, 0.0, ticket);
}

int BuyStopNoError(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (actual == ERR_NO_ERROR)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int SellStopNoError(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (actual == ERR_NO_ERROR)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int OpBuyWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_BUY;
    const double entryPrice = Ask;

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int OpSellWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_SELL;
    const double entryPrice = Bid;

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int OpBuyLimitWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYLIMIT;
    const double entryPrice = Ask - OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int OpSellLimitWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLLIMIT;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int StopLossAboveBuyStopEntryError(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice + OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}

int StopLossBelowSellStopEntryError(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice - OrderHelper::PipsToRange(50);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return actual;
}
