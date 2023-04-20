//+------------------------------------------------------------------+
//|                                               PlaceStopOrder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/PlaceStopOrder/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1ktWEr9cPMb2aQq8OKgIKgD0qHCENnUDZ/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BuyStopNoErrorUnitTest;

// https://drive.google.com/file/d/1_mHY2Tdr8DEAeuNr7-T-65SxDfkMvzAy/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *SellStopNoErrorUnitTest;

// https://drive.google.com/file/d/1vBAXpWHb_qPRrxYQS3PRF9rG5Oof6uzq/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *OpBuyWrongOrderTypeUnitTest;

// https://drive.google.com/file/d/1vBxjuJOfNgJfxQGu_ImDPh9E6O6YjJMF/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *OpSellWrongOrderTypeUnitTest;

// https://drive.google.com/file/d/1X2OnXaes45lzI1LH28ZxbwMp6_LGBIgP/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *OpBuyLimitWrongOrderTypeUnitTest;

// https://drive.google.com/file/d/1haPZmRHGg8LlDqDwLy-KSmNS_KibX4Ci/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *OpSellLimitWrongOrderTypeUnitTest;

// https://drive.google.com/file/d/1wbGy0o_3m2CtU0TOPAqZnmux-uNJOmAY/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *StopLossAboveBuyStopEntryErrorUnitTest;

// https://drive.google.com/file/d/1k2eaG9tWW1VM-c-XNhkZGEnhbxslksNz/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *StopLossBelowSellStopEntryErrorUnitTest;

// https://drive.google.com/file/d/1SFesknKwasDQvpRUQKchtNSkQGtgBmZN/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BuyStopEntryBelowAskUnitTest;

// https://drive.google.com/file/d/1fjl8h5qTmZNs0uG3RFpPutl-jdJYFYQx/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *SellStopEntryAboveBidUnitTest;

int OnInit()
{
    BuyStopNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Buy Stop No Errrors", "No Errors When Placing Buy Stop Orders",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::NO_ERROR, BuyStopNoError);

    SellStopNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Sell Stop No Errors", "No Errors When Placing Sell Stop ORders",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::NO_ERROR, SellStopNoError);

    OpBuyWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Wrong Order Type", "Returns Error When Placing OP Buy",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::WRONG_ORDER_TYPE, OpBuyWrongOrderType);

    OpSellWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Wrong Order Type", "Returns Error When Placing OP Sell",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::WRONG_ORDER_TYPE, OpSellWrongOrderType);

    OpBuyLimitWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Buy Limit Wrong Order Type", "Returns Error When Placing OP Buy Limit",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::WRONG_ORDER_TYPE, OpBuyLimitWrongOrderType);

    OpSellLimitWrongOrderTypeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "OP Sell Limit Wrong Order Type", "Returns Error When Placing OP Sell Limit",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::WRONG_ORDER_TYPE, OpSellLimitWrongOrderType);

    StopLossAboveBuyStopEntryErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Stop Loss Above Buy Stop Entry Error", "Returns Error When Stop Loss is Above Buy Stop Entry",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::STOPLOSS_PAST_ENTRY, StopLossAboveBuyStopEntryError);

    StopLossBelowSellStopEntryErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Stop Loss Below Sell Stop Entry Error", "Returns Error When Stop Loss Is Below Sell Stop Entry",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::STOPLOSS_PAST_ENTRY, StopLossBelowSellStopEntryError);

    BuyStopEntryBelowAskUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Buy Stop Entry Below Ask", "Returns Buy Stop Entry Below Ask Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::STOP_ORDER_ENTRY_FURTHER_THEN_PRICE, BuyStopEntryBelowAsk);

    SellStopEntryAboveBidUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Sell Stop Entry Above Bid", "Returns Sell Stop Entry Above Bid Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::STOP_ORDER_ENTRY_FURTHER_THEN_PRICE, SellStopEntryAboveBid);

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

    delete BuyStopEntryBelowAskUnitTest;
    delete SellStopEntryAboveBidUnitTest;
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

    BuyStopEntryBelowAskUnitTest.Assert();
    SellStopEntryAboveBidUnitTest.Assert();
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
    return PlaceStopOrder(type, entryPrice, 0.0, ticket);
}

int BuyStopNoError(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(200);
    const double stopLoss = Bid - OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int SellStopNoError(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(200);
    const double stopLoss = Ask + OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int OpBuyWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_BUY;
    const double entryPrice = Ask;

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderClose(ticket, 0.1, Bid, 0, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int OpSellWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_SELL;
    const double entryPrice = Bid;

    actual = PlaceStopOrder(type, entryPrice, ticket);
    if (ticket > 0)
    {
        OrderClose(ticket, 0.1, Ask, 0, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int OpBuyLimitWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYLIMIT;
    const double entryPrice = Ask - OrderHelper::PipsToRange(200);
    const double stopLoss = Ask - OrderHelper::PipsToRange(300);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int OpSellLimitWrongOrderType(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLLIMIT;
    const double entryPrice = Ask + OrderHelper::PipsToRange(200);
    const double stopLoss = Ask + OrderHelper::PipsToRange(300);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int StopLossAboveBuyStopEntryError(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask + OrderHelper::PipsToRange(200);
    const double stopLoss = entryPrice + OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int StopLossBelowSellStopEntryError(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid - OrderHelper::PipsToRange(200);
    const double stopLoss = entryPrice - OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int BuyStopEntryBelowAsk(int &actual)
{
    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double entryPrice = Ask - OrderHelper::PipsToRange(200);
    const double stopLoss = Bid - OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}

int SellStopEntryAboveBid(int &actual)
{
    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double entryPrice = Bid + OrderHelper::PipsToRange(200);
    const double stopLoss = Ask + OrderHelper::PipsToRange(200);

    actual = PlaceStopOrder(type, entryPrice, stopLoss, ticket);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return Results::UNIT_TEST_RAN;
}