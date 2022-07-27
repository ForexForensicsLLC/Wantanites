//+------------------------------------------------------------------+
//|                                    GetEntryPriceForStopOrder.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/GetEntryForStopOrder/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete bullishMBNoErrorsUnitTest;
    delete bearishMBNoErrorsUnitTest;

    delete bullishMBEmptyRetracementUnitTest;
    delete bearishMBEmptyRetracementUnitTest;

    delete bullishMBCorrectEntryPriceUnitTest;
    delete bearishMBCorrectEntryPriceUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBNoErrors();
    BearishMBNoErrors();

    BullishMBEmptyRetracement();
    BearishMBEmptyRetracement();

    BullishMBCorrectEntryPrice();
    BearishMBCorrectEntryPrice();
}

bool GetEntryPriceForStopOrderSetup(int type, bool shouldHaveRetracment)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return false;
    }

    if (tempMBState.Type() != type)
    {
        return false;
    }

    if (type == OP_BUY)
    {
        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }
    else if (type == OP_SELL)
    {
        int retracementIndex = MBT.CurrentBearishRetracementIndex();
        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }

    return true;
}

UnitTest<DefaultUnitTestRecord> *bullishMBNoErrorsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BullishMBNoErrors()
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return;
    }

    bullishMBNoErrorsUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    bullishMBNoErrorsUnitTest.assertEquals("Get Entry Price For Stop Order On Most Recent Pending Bullish MB No Error", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *bearishMBNoErrorsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BearishMBNoErrors()
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return;
    }

    bearishMBNoErrorsUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int expected = ERR_NO_ERROR;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    bearishMBNoErrorsUnitTest.assertEquals("Get Entry Price For Stop Order On Most Recent Pending Bearish MB No Error", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *bullishMBEmptyRetracementUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BullishMBEmptyRetracement()
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, false))
    {
        return;
    }

    bullishMBEmptyRetracementUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int expected = Errors::ERR_EMPTY_BULLISH_RETRACEMENT;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    bullishMBEmptyRetracementUnitTest.assertEquals("Get Entry Price For Stop Order On Most Recent Pending Bullish MB Invalid Retracement", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *bearishMBEmptyRetracementUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BearishMBEmptyRetracement()
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, false))
    {
        return;
    }

    bearishMBEmptyRetracementUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int expected = Errors::ERR_EMPTY_BEARISH_RETRACEMENT;
    int actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    bearishMBEmptyRetracementUnitTest.assertEquals("Get Entry Price For Stop Order On Most Recent Pending Bullish MB Invalid Retracement", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *bullishMBCorrectEntryPriceUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BullishMBCorrectEntryPrice()
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return;
    }

    bullishMBCorrectEntryPriceUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    int expected = MathFloor((iHigh(Symbol(), Period(), MBT.CurrentBullishRetracementIndex()) * MathPow(10, _Digits)));
    int actual = MathFloor((entryPrice * MathPow(10, _Digits)));

    bullishMBCorrectEntryPriceUnitTest.assertEquals("Get Entry Price For Buy Stop Order On Most Recent Bullish Pending MB Correct Entry", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *bearishMBCorrectEntryPriceUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BearishMBCorrectEntryPrice()
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return;
    }

    bearishMBCorrectEntryPriceUnitTest.addTest(__FUNCTION__);

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);

    int expected = MathFloor((iLow(Symbol(), Period(), MBT.CurrentBearishRetracementIndex()) * MathPow(10, _Digits)));
    int actual = MathFloor((entryPrice * MathPow(10, _Digits)));

    bearishMBCorrectEntryPriceUnitTest.assertEquals("Get Entry Price For Sell Stop Order On Most Recent Bearish Pending MB Correct Entry", expected, actual);
}
