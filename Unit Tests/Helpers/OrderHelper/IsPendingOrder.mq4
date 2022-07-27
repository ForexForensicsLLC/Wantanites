//+------------------------------------------------------------------+
//|                                               IsPendingOrder.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/IsPendingOrder/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete opBuyIsNotPendingUnitTest;
    delete opSellIsNotPendingUnitTest;
    delete opBuyStopIsPendingUnitTest;
    delete opSellStopIsPendingUnitTest;
    delete opBuyLimitIsPendingUnitTest;
    delete opSellLimitIsPendingUnitTest;
}

void OnTick()
{
    OP_BUYIsNotPending();
    OP_SELLIsNotPending();

    OP_BUYSTOPIsPending();
    OP_SELLSTOPIsPending();

    OP_BUYLIMITIsPending();
    OP_SELLLIMITIsPending();
}

UnitTest<DefaultUnitTestRecord> *opBuyIsNotPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_BUYIsNotPending()
{
    int type = OP_BUY;
    int ticket = OrderSend(Symbol(), type, 0.1, Ask, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = false;
        bool actual = true;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opBuyIsNotPendingUnitTest.addTest(__FUNCTION__);
        opBuyIsNotPendingUnitTest.assertEquals("Buy is not Pending Order", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *opSellIsNotPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_SELLIsNotPending()
{
    int type = OP_SELL;
    int ticket = OrderSend(Symbol(), type, 0.1, Bid, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = false;
        bool actual = true;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opBuyIsNotPendingUnitTest.addTest(__FUNCTION__);
        opBuyIsNotPendingUnitTest.assertEquals("Sell is not Pending Order", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *opBuyStopIsPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_BUYSTOPIsPending()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = true;
        bool actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opBuyStopIsPendingUnitTest.addTest(__FUNCTION__);
        opBuyStopIsPendingUnitTest.assertEquals("Buy Stop is Pending Order", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *opSellStopIsPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_SELLSTOPIsPending()
{
    int type = OP_SELLSTOP;
    int entryPrice = Bid - OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = true;
        bool actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opSellStopIsPendingUnitTest.addTest(__FUNCTION__);
        opSellStopIsPendingUnitTest.assertEquals("Sell Stop is Pending Order", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *opBuyLimitIsPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_BUYLIMITIsPending()
{
    int type = OP_BUYLIMIT;
    int entryPrice = Bid - OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = true;
        bool actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opBuyLimitIsPendingUnitTest.addTest(__FUNCTION__);
        opBuyLimitIsPendingUnitTest.assertEquals("Buy Limit is Pending Order", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *opSellLimitIsPendingUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void OP_SELLLIMITIsPending()
{
    int type = OP_SELLLIMIT;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        const bool expected = true;
        bool actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return;
        }

        opSellLimitIsPendingUnitTest.addTest(__FUNCTION__);
        opSellLimitIsPendingUnitTest.assertEquals("Sell Limit is Pending Order", expected, actual);
    }
}
