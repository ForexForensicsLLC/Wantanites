//+------------------------------------------------------------------+
//|                                                     Template.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#property show_inputs

// Make sure path is correct
#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 7;
input double RiskPercent = 0.25;

// -- MBTracker Inputs
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

// --- EA Globals ---
UnitTest *UT;
MBTracker *MBT;

bool FirstTick = true;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);
    UT = new UnitTest();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
}

void OnTick()
{
    if (FirstTick)
    {
        RangeToPips_EURUSD();
        RangeToPips_NASDAQ();

        PipsToRange_NASDAQ();
        PipsToRange_EURUSD();

        SelectOpenOrderByTicket_NoError();
        SelectOpenOrderByTicket_Error();

        IsPendingOrder_OP_BUYSTOP();
        IsPendingOrder_OP_SELLSTOP();
        IsPendingOrder_OP_BUYLIMIT();
        IsPendingOrder_OP_SELLLIMIT();

        OtherEAOrders_None();
        OtherEAOrders_MultipleOrdersFromOneEA();
        OtherEAOrders_MultipleOrdersFromMultipleEAs();

        PlaceStopOrder_NoError();
        PlaceStopOrder_WrongOrderType();
        PlaceStopOrder_StopLossAboveBuyStopEntry();
        PlaceStopOrder_StopLossBelowSellStopEntry();

        CancelPendingOrderByTicket_NoErrorsEmptyTicket();
        CancelPendingOrderByTicket_ErrorsNotEmptyTicket();

        FirstTick = false;
    }
    else
    {
        GetEntryPriceForStopOrder_BullishMBNoErrors();
        GetEntryPriceForStopOrder_BearishMBNoErrors();
        GetEntryPriceForStopOrder_BullishMBEmptyRetracement();
        GetEntryPriceForStopOrder_BearishMBEmptyRetracement();
        GetEntryPriceForStopOrder_CorrectBullishMBEntryPrice();
        GetEntryPriceForStopOrder_CorrectBearishMBEntryPrice();

        PlaceStopOrderOnMostRecentPendingMB_BullishMBNoError();
        PlaceStopOrderOnMostRecentPendingMB_BearishMBNoError();
        PlaceStopOrderOnMostRecentPendingMB_NotMostRecentMB();

        CheckEditStopLossForMostRecentMBStopOrder_SameTicket();
        CheckEditStopLossForMostRecentMBStopOrder_DifferentStopLoss();

        CheckTrailStopLossWithMB_TrailNoErrorsDifferntStopLoss();
        CheckTrailStopLossWithMB_TrailNotPastOpen();
    }
}

void RangeToPips_NASDAQ()
{
    if (Symbol() == "US100.cash")
    {
        UT.addTest(__FUNCTION__);

        const double range = 0.1;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1.0;

        UT.assertEquals(__FUNCTION__, "Range to Pips", expected, actual);
    }
}

void RangeToPips_EURUSD()
{
    if (Symbol() == "EURUSD")
    {
        UT.addTest(__FUNCTION__);

        const double range = 0.00001;

        const double actual = OrderHelper::RangeToPips(range);
        const double expected = 1;

        UT.assertEquals(__FUNCTION__, "Range to Pips", expected, actual);
    }
}

void PipsToRange_NASDAQ()
{
    if (Symbol() == "US100.cash")
    {
        UT.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.1;

        UT.assertEquals(__FUNCTION__, "Pips to Range", expected, actual);
    }
}

void PipsToRange_EURUSD()
{
    if (Symbol() == "EURUSD")
    {
        UT.addTest(__FUNCTION__);

        const double pips = 1;

        const double actual = OrderHelper::PipsToRange(pips);
        const double expected = 0.00001;

        UT.assertEquals(__FUNCTION__, "Pips to Range", expected, actual);
    }
}

void GetEntryPriceForStopOrder_BullishMBNoErrors()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBullishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Stop Order On Most Recent Pending Bullish MB No Error", expected, actual);
}

void GetEntryPriceForStopOrder_BearishMBNoErrors()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBearishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Stop Order On Most Recent Pending Bearish MB No Error", expected, actual);
}

void GetEntryPriceForStopOrder_BullishMBEmptyRetracement()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBullishRetracementIndex();
    if (retracementIndex != EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    int expected = Errors::ERR_EMPTY_BULLISH_RETRACEMENT;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Stop Order On Most Recent Pending Bullish MB Invalid Retracement", expected, actual);
}

void GetEntryPriceForStopOrder_BearishMBEmptyRetracement()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBearishRetracementIndex();
    if (retracementIndex != EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    int expected = Errors::ERR_EMPTY_BEARISH_RETRACEMENT;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Stop Order On Most Recent Pending Bullish MB Invalid Retracement", expected, actual);
}

void GetEntryPriceForStopOrder_CorrectBullishMBEntryPrice()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBullishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    int expected = MathFloor((iHigh(Symbol(), Period(), retracementIndex) * MathPow(10, _Digits)));
    int actual = MathFloor((entryPrice * MathPow(10, _Digits)));

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Buy Stop Order On Most Recent Bullish Pending MB Correct Entry", expected, actual);
}

void GetEntryPriceForStopOrder_CorrectBearishMBEntryPrice()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBearishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;
    int setupType = OP_BUY;

    OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    int expected = MathFloor((iLow(Symbol(), Period(), retracementIndex) * MathPow(10, _Digits)));
    int actual = MathFloor((entryPrice * MathPow(10, _Digits)));

    UT.assertEquals(__FUNCTION__, "Get Entry Price For Sell Stop Order On Most Recent Bearish Pending MB Correct Entry", expected, actual);
}

void SelectOpenOrderByTicket_NoError()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const double entryPrice = Ask + OrderHelper::PipsToRange(10);
    const double lots = 0.1;
    const int slippage = 0;
    const double stopLoss = 0.0;
    const double takeProfit = 0.0;
    const string comment = NULL;
    const int magicNumber = 0;
    const datetime expiration = 0;
    const color col = clrNONE;

    ticket = OrderSend(Symbol(), OP_BUYSTOP, lots, entryPrice, slippage, stopLoss, takeProfit, comment, magicNumber, expiration, col);

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");

    UT.assertEquals(__FUNCTION__, "Select Order By Ticket No Errors", expected, actual);

    OrderDelete(ticket, clrNONE);
}

void SelectOpenOrderByTicket_Error()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const double entryPrice = Ask + OrderHelper::PipsToRange(10);
    const double lots = 0.1;
    const int slippage = 0;
    const double stopLoss = 0.0;
    const double takeProfit = 0.0;
    const string comment = NULL;
    const int magicNumber = 0;
    const datetime expiration = 0;
    const color col = clrNONE;

    ticket = OrderSend(Symbol(), OP_BUYSTOP, lots, entryPrice, slippage, stopLoss, takeProfit, comment, magicNumber, expiration, col);
    OrderDelete(ticket, clrNONE);

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing selecing order");

    if (actual > 1)
    {
        expected = actual;
    }

    UT.assertEquals(__FUNCTION__, "Select Order By Ticket When No Current Orders Errors", expected, actual);
}

void IsPendingOrder_OP_BUYSTOP()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        bool actual = false;
        OrderHelper::IsPendingOrder(ticket, actual);
        const bool expected = true;

        UT.assertEquals(__FUNCTION__, "Buy Stop is Pending Order", expected, actual);
    }
}

void IsPendingOrder_OP_SELLSTOP()
{
    int type = OP_SELLSTOP;
    int entryPrice = Bid - OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        bool actual = false;
        OrderHelper::IsPendingOrder(ticket, actual);
        const bool expected = true;

        UT.assertEquals(__FUNCTION__, "Sell Stop is Pending Order", expected, actual);
    }
}

void IsPendingOrder_OP_BUYLIMIT()
{
    int type = OP_BUYLIMIT;
    int entryPrice = Bid - OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        bool actual = false;
        OrderHelper::IsPendingOrder(ticket, actual);
        const bool expected = true;

        UT.assertEquals(__FUNCTION__, "Buy Limit is Pending Order", expected, actual);
    }
}

void IsPendingOrder_OP_SELLLIMIT()
{
    int type = OP_SELLLIMIT;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        bool actual = false;
        OrderHelper::IsPendingOrder(ticket, actual);
        const bool expected = true;

        UT.assertEquals(__FUNCTION__, "Sell Limit is Pending Order", expected, actual);
    }
}

void OtherEAOrders_None()
{
    UT.addTest(__FUNCTION__);

    int magicNumberOne = 001;
    int magicNumberTwo = 002;
    int magicNumberThree = 003;

    int magicNumberArray[];
    ArrayResize(magicNumberArray, 3);

    magicNumberArray[0] = magicNumberOne;
    magicNumberArray[1] = magicNumberTwo;
    magicNumberArray[2] = magicNumberThree;

    const int expected = 0;
    int actual;
    OrderHelper::OtherEAOrders(magicNumberArray, actual);

    UT.assertEquals(__FUNCTION__, "Zero Orders From Multiple EAs", expected, actual);
}

void OtherEAOrders_MultipleOrdersFromOneEA()
{
    int magicNumberOne = 001;
    int magicNumberTwo = 002;
    int magicNumberThree = 003;

    int magicNumberArray[];
    ArrayResize(magicNumberArray, 3);

    magicNumberArray[0] = magicNumberOne;
    magicNumberArray[1] = magicNumberTwo;
    magicNumberArray[2] = magicNumberThree;

    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, magicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, magicNumberOne, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {
        UT.addTest(__FUNCTION__);

        const int expected = 2;
        int actual;
        OrderHelper::OtherEAOrders(magicNumberArray, actual);

        UT.assertEquals(__FUNCTION__, "Multiple Orders From One EA", expected, actual);

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);
    }
}

void OtherEAOrders_MultipleOrdersFromMultipleEAs()
{
    int magicNumberOne = 001;
    int magicNumberTwo = 002;
    int magicNumberThree = 003;

    int magicNumberArray[];
    ArrayResize(magicNumberArray, 3);

    magicNumberArray[0] = magicNumberOne;
    magicNumberArray[1] = magicNumberTwo;
    magicNumberArray[2] = magicNumberThree;

    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, magicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, magicNumberTwo, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {
        UT.addTest(__FUNCTION__);

        const int expected = 2;
        int actual;
        OrderHelper::OtherEAOrders(magicNumberArray, actual);

        UT.assertEquals(__FUNCTION__, "Multiple Orders From Multiple EAs", expected, actual);

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);
    }
}

void PlaceStopOrder_NoError()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double lots = 0.1;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);
    const double stopLoss = 0.0;
    const double takeProfit = 0.0;
    const int magicNumber = 0;

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, magicNumber, ticket);

    UT.assertEquals(__FUNCTION__, "No Errors When Placing Stop Order", expected, actual);

    if (actual == ERR_NO_ERROR)
    {
        OrderDelete(ticket, clrNONE);
    }
}

void PlaceStopOrder_WrongOrderType()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int type = OP_BUY;
    const double lots = 0.1;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);
    const double stopLoss = 0.0;
    const double takeProfit = 0.0;
    const int magicNumber = 0;

    int expected = Errors::ERR_WRONG_ORDER_TYPE;
    int actual = OrderHelper::PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, magicNumber, ticket);

    UT.assertEquals(__FUNCTION__, "No Errors When Placing Stop Order", expected, actual);
}

void PlaceStopOrder_StopLossAboveBuyStopEntry()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int type = OP_BUYSTOP;
    const double lots = 0.1;
    const double entryPrice = Ask + OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice + OrderHelper::PipsToRange(50);
    const double takeProfit = 0.0;
    const int magicNumber = 0;

    int expected = Errors::ERR_STOPLOSS_ABOVE_ENTRY;
    int actual = OrderHelper::PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, magicNumber, ticket);

    UT.assertEquals(__FUNCTION__, "Stop Loss Above Buy Stop Entry", expected, actual);
}

void PlaceStopOrder_StopLossBelowSellStopEntry()
{
    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int type = OP_SELLSTOP;
    const double lots = 0.1;
    const double entryPrice = Bid - OrderHelper::PipsToRange(50);
    const double stopLoss = entryPrice - OrderHelper::PipsToRange(50);
    const double takeProfit = 0.0;
    const int magicNumber = 0;

    int expected = Errors::ERR_STOPLOSS_ABOVE_ENTRY;
    int actual = OrderHelper::PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, magicNumber, ticket);

    UT.assertEquals(__FUNCTION__, "Stop Loss Below Sell Stop Entry", expected, actual);
}

void PlaceStopOrderOnMostRecentPendingMB_BullishMBNoError()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBullishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;
    const int setupMBNumber = tempMBState.Number();

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);

    UT.assertEquals(__FUNCTION__, "Place Stop Order On Most Recent Bullish MB No Error", expected, actual);

    OrderDelete(ticket, clrNONE);
}

void PlaceStopOrderOnMostRecentPendingMB_BearishMBNoError()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    int retracementIndex = MBT.CurrentBearishRetracementIndex();
    if (retracementIndex == EMPTY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;
    const int setupMBNumber = tempMBState.Number();

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);

    UT.assertEquals(__FUNCTION__, "Place Stop Order On Most Recent Bearish MB No Error", expected, actual);

    OrderDelete(ticket, clrNONE);
}

void PlaceStopOrderOnMostRecentPendingMB_NotMostRecentMB()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(2, tempMBState))
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    int ticket = -1;
    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;
    const int setupMBNumber = tempMBState.Number();

    int expected = Errors::ERR_MB_IS_NOT_MOST_RECENT;
    int actual = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);

    UT.assertEquals(__FUNCTION__, "Place Stop Order On Not Most Recent MB", expected, actual);
}

void CheckEditStopLossForMostRecentMBStopOrder_SameTicket()
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    // make sure we have a setup
    if (stopLoss == 0.0)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        int oldTicket = ticket;
        int editStopLossError = OrderHelper::CheckEditStopLossForMostRecentMBStopOrder(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);

        if (editStopLossError != Errors::ERR_NEW_STOPLOSS_EQUALS_OLD)
        {
            return;
        }

        UT.addTest(__FUNCTION__);

        bool expected = true;
        bool actual = oldTicket == ticket;

        UT.assertEquals(__FUNCTION__, "Check Edit Stop Loss For Most Recent MB Same Ticket", expected, actual);
    }
}

void CheckEditStopLossForMostRecentMBStopOrder_DifferentStopLoss()
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    // make sure we have a setup
    if (stopLoss == 0.0)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        int oldTicket = ticket;
        int editStopLossError = OrderHelper::CheckEditStopLossForMostRecentMBStopOrder(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);

        if (editStopLossError != ERR_NO_ERROR)
        {
            return;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        UT.addTest(__FUNCTION__);

        bool expected = true;
        bool actual = stopLoss == OrderStopLoss();

        UT.assertEquals(__FUNCTION__, "Check Edit Stop Loss For Most Recent MB Different Stop Loss", expected, actual);
    }
}

void CancelPendingOrderByTicket_NoErrorsEmptyTicket()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        int errors = OrderHelper::CancelPendingOrderByTicket(ticket);
        if (errors != ERR_NO_ERROR)
        {
            return;
        }

        bool expected = true;
        bool actual = ticket == EMPTY;

        UT.assertEquals(__FUNCTION__, "Cancel Pending Order By Ticket No Errors Empty Ticket", expected, actual);
    }
}

void CancelPendingOrderByTicket_ErrorsNotEmptyTicket()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        UT.addTest(__FUNCTION__);

        OrderDelete(ticket, clrNONE);

        int errors = OrderHelper::CancelPendingOrderByTicket(ticket);
        if (errors == ERR_NO_ERROR)
        {
            return;
        }

        bool expected = true;
        bool actual = ticket != EMPTY;

        UT.assertEquals(__FUNCTION__, "Cancel Pending Order By Ticket Errors Not Empty Ticket", expected, actual);
    }
}

void CheckTrailStopLossWithMB_TrailNoErrorsDifferntStopLoss()
{
    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            setupType = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    if (ticket == -1)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();
        setupType = tempMBState.Type();
        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        stopLoss = OrderStopLoss();
    }
    else
    {
        bool succeeded = false;
        int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, paddingPips, spreadPips, mbNumber, setupType, MBT, succeeded);
        if (!succeeded)
        {
            return;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        UT.addTest(__FUNCTION__);

        const bool expected = true;
        const bool actual = OrderStopLoss() != stopLoss;

        UT.assertEquals(__FUNCTION__, "Check Trail Stop Loss With MB Up To Break Even No Errors Differnt Stop Loss", expected, actual);

        OrderClose(ticket, OrderLots(), Ask, 0, clrNONE);
    }
}

void CheckTrailStopLossWithMB_TrailNotPastOpen()
{
    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            setupType = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    if (ticket == -1)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();
        setupType = tempMBState.Type();
        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        stopLoss = OrderStopLoss();
        entryPrice = OrderOpenPrice();
    }
    else
    {
        bool succeeded = false;
        int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, paddingPips, spreadPips, mbNumber, setupType, MBT, succeeded);
        if (!succeeded)
        {
            return;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        UT.addTest(__FUNCTION__);

        const bool expected = true;
        bool actual = false;

        if (setupType == OP_BUY)
        {
            actual = OrderStopLoss() <= entryPrice;
        }
        else if (setupType == OP_SELL)
        {
            actual = OrderStopLoss() >= entryPrice;
        }

        UT.assertEquals(__FUNCTION__, "Check Trail Stop Loss With MB Up To Break Even Not Past Open", expected, actual);
    }
}