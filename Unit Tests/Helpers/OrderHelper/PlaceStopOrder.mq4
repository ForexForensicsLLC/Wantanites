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
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/PlaceStopOrder/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete buyStopNoErrorUnitTest;
    delete sellStopNoErrorUnitTest;

    delete opBuyWrongOrderTypeUnitTest;
    delete opSellWrongOrderTypeUnitTest;
    delete opBuyLimitWrongOrderTypeUnitTest;
    delete opSellLimitWrongOrderTypeUnitTest;

    delete stopLossAboveBuyStopEntryErrorUnitTest;
    delete stopLossAboveSellStopEntryErrorUnitTest;
}

void OnTick()
{
    BuyStopNoError();
    SellStopNoError();

    OpBuyWrongOrderType();
    OpSellWrongOrderType();
    OpBuyLimitWrongOrderType();
    OpSellLimitWrongOrderType();

    StopLossAboveBuyStopEntryError();
    StopLossBelowSellStopEntryError();
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

UnitTest<DefaultUnitTestRecord> *buyStopNoErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BuyStopNoError()
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);

    int expected = ERR_NO_ERROR;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    buyStopNoErrorUnitTest.addTest(__FUNCTION__);
    buyStopNoErrorUnitTest.assertEquals("No Errors When Placing Buy Stop Order", expected, actual);

    if (actual == ERR_NO_ERROR)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *sellStopNoErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void SellStopNoError()
{

    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(50);

    int expected = ERR_NO_ERROR;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    sellStopNoErrorUnitTest.addTest(__FUNCTION__);
    sellStopNoErrorUnitTest.assertEquals("No Errors When Placing Sell Stop Order", expected, actual);

    if (actual == ERR_NO_ERROR)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *opBuyWrongOrderTypeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OpBuyWrongOrderType()
{
    int ticket = -1;
    const int type = OP_BUY;
    const double entryPrice = Ask;

    int expected = Errors::ERR_WRONG_ORDER_TYPE;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    opBuyWrongOrderTypeUnitTest.addTest(__FUNCTION__);
    opBuyWrongOrderTypeUnitTest.assertEquals("OP Buy Is Wrong Order Type", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *opSellWrongOrderTypeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OpSellWrongOrderType()
{
    int ticket = -1;
    const int type = OP_SELL;
    const double entryPrice = Bid;

    int expected = Errors::ERR_WRONG_ORDER_TYPE;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    opSellWrongOrderTypeUnitTest.addTest(__FUNCTION__);
    opSellWrongOrderTypeUnitTest.assertEquals("OP Sell Is Wrong Order Type", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *opBuyLimitWrongOrderTypeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OpBuyLimitWrongOrderType()
{
    int ticket = -1;
    const int type = OP_BUYLIMIT;
    const double entryPrice = Ask - OrderHelper::PipsToRange(50);

    int expected = Errors::ERR_WRONG_ORDER_TYPE;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    opBuyLimitWrongOrderTypeUnitTest.addTest(__FUNCTION__);
    opBuyLimitWrongOrderTypeUnitTest.assertEquals("OP Buy Limit Is Wrong Order Type", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *opSellLimitWrongOrderTypeUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OpSellLimitWrongOrderType()
{
    int ticket = -1;
    const int type = OP_SELLLIMIT;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);

    int expected = Errors::ERR_WRONG_ORDER_TYPE;
    int actual = PlaceStopOrder(type, entryPrice, ticket);

    opSellLimitWrongOrderTypeUnitTest.addTest(__FUNCTION__);
    opSellLimitWrongOrderTypeUnitTest.assertEquals("OP Buy Is Wrong Order Type", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *stopLossAboveBuyStopEntryErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void StopLossAboveBuyStopEntryError()
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice + OrderHelper::PipsToRange(50);

    int expected = Errors::ERR_STOPLOSS_ABOVE_ENTRY;
    int actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);

    stopLossAboveBuyStopEntryErrorUnitTest.addTest(__FUNCTION__);
    stopLossAboveBuyStopEntryErrorUnitTest.assertEquals("Stop Loss Above Buy Stop Entry Error", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *stopLossAboveSellStopEntryErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void StopLossBelowSellStopEntryError()
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice - OrderHelper::PipsToRange(50);

    int expected = Errors::ERR_STOPLOSS_ABOVE_ENTRY;
    int actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);

    stopLossAboveSellStopEntryErrorUnitTest.addTest(__FUNCTION__);
    stopLossAboveSellStopEntryErrorUnitTest.assertEquals("Stop Loss Below Sell Stop Entry", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}
