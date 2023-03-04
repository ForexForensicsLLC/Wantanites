//+------------------------------------------------------------------+
//|                                               IsPendingOrder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/IsPendingOrder/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1mTmG4IHHAKdLqvyMo4t3OS91eKuNJ5AU/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpBuyIsNotPendingUnitTest;

// https://drive.google.com/file/d/1Pn2yMu7uXuwGPvzx3kP9l-gBBImuxIBs/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpSellIsNotPendingUnitTest;

// https://drive.google.com/file/d/1cYOKMq53YcJ7O_ciELMTtmAPYr2khWW6/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpBuyStopIsPendingUnitTest;

// https://drive.google.com/file/d/1NNUuLYTgqaPPIWLYuhAV0mtijaIDrxpC/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpSellStopIsPendingUnitTest;

// https://drive.google.com/file/d/13PQL6B8Xoz8W7ij9TMIMdCCWJ_TwMfCn/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpBuyLimitIsPendingUnitTest;

// https://drive.google.com/file/d/1m1rqIOe9lFV7DZSvvZFuZqWZksYjhV57/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *OpSellLimitIsPendingUnitTest;

int OnInit()
{
    OpBuyIsNotPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Is Not Pending", "Checks If OP_BUY Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, OpBuyIsNotPending);

    OpSellIsNotPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Is Not Pending", "Checks If OP_SELL Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, OpSellIsNotPending);

    OpBuyStopIsPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Stop Is Pending Order", "Checks If OP_BUYSTOP Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, OpBuyStopIsPending);

    OpSellStopIsPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Stop Is Pending Order", "Checks If OP_SELLSTOP Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, OpSellStopIsPending);

    OpBuyLimitIsPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Limit Is Pending Order", "Checks If OP_BUYLIMIT Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, OpBuyLimitIsPending);

    OpSellLimitIsPendingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Limit Is Pending Order", "Checks If OP_SELLLIMIT Is A Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, OpSellLimitIsPending);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete OpBuyIsNotPendingUnitTest;
    delete OpSellIsNotPendingUnitTest;

    delete OpBuyStopIsPendingUnitTest;
    delete OpSellStopIsPendingUnitTest;

    delete OpBuyLimitIsPendingUnitTest;
    delete OpSellLimitIsPendingUnitTest;
}

void OnTick()
{
    OpBuyIsNotPendingUnitTest.Assert();
    OpSellIsNotPendingUnitTest.Assert();

    OpBuyStopIsPendingUnitTest.Assert();
    OpSellStopIsPendingUnitTest.Assert();

    OpBuyLimitIsPendingUnitTest.Assert();
    OpSellLimitIsPendingUnitTest.Assert();
}

int OpBuyIsNotPending(bool &actual)
{
    int type = OP_BUY;
    int ticket = OrderSend(Symbol(), type, 0.1, Ask, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = true;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderClose(ticket, 0.1, Bid, 0, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int OpSellIsNotPending(bool &actual)
{
    int type = OP_SELL;
    int ticket = OrderSend(Symbol(), type, 0.1, Bid, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = true;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderClose(ticket, 0.1, Ask, 0, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int OpBuyStopIsPending(bool &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int OpSellStopIsPending(bool &actual)
{
    int type = OP_SELLSTOP;
    double entryPrice = Bid - OrderHelper::PipsToRange(100);
    double stopLoss = Ask + OrderHelper::PipsToRange(100);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int OpBuyLimitIsPending(bool &actual)
{
    int type = OP_BUYLIMIT;
    double entryPrice = Bid - OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(200);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int OpSellLimitIsPending(bool &actual)
{
    int type = OP_SELLLIMIT;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Ask + OrderHelper::PipsToRange(200);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = false;

        int pendingOrderError = OrderHelper::IsPendingOrder(ticket, actual);
        if (pendingOrderError != ERR_NO_ERROR)
        {
            return pendingOrderError;
        }

        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }

        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}
