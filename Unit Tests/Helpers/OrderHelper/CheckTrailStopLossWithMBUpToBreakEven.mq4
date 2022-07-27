//+------------------------------------------------------------------+
//|                                     CheckTrailStopLossWithMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Errors.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CheckTrailStopLossWithMBUpToBreakEven/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 0;

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
    delete noErrorsDifferentStopLossUnitTest;
    delete doesNotTrailPastOpenUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    NoErrorsDifferentStopLoss();
    DoesNotTrailPastOpen();
}

UnitTest<DefaultUnitTestRecord> *noErrorsDifferentStopLossUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void NoErrorsDifferentStopLoss()
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

            if (ticket > 0)
            {
                bool isTrue = false;
                int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isTrue);
                if (isTrue)
                {
                    OrderHelper::CancelPendingOrderByTicket(ticket);
                }
                else
                {
                    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Trailing Stop Loss");
                    if (selectError != ERR_NO_ERROR)
                    {
                        return;
                    }

                    OrderClose(ticket, OrderLots(), Ask, 0, clrNONE);
                }
            }

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

        const bool expected = true;
        const bool actual = OrderStopLoss() != stopLoss;

        noErrorsDifferentStopLossUnitTest.addTest(__FUNCTION__);
        noErrorsDifferentStopLossUnitTest.assertEquals("No Errors, Different Stop Loss", expected, actual);

        if (ticket > 0)
        {
            OrderClose(ticket, OrderLots(), Ask, 0, clrNONE);
        }
    }
}

UnitTest<DefaultUnitTestRecord> *doesNotTrailPastOpenUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void DoesNotTrailPastOpen()
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

            if (ticket > 0)
            {
                bool isTrue = false;
                int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isTrue);
                if (isTrue)
                {
                    OrderHelper::CancelPendingOrderByTicket(ticket);
                }
                else
                {
                    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Trailing Stop Loss");
                    if (selectError != ERR_NO_ERROR)
                    {
                        return;
                    }

                    OrderClose(ticket, OrderLots(), Ask, 0, clrNONE);
                }
            }

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

        doesNotTrailPastOpenUnitTest.addTest(__FUNCTION__);
        doesNotTrailPastOpenUnitTest.assertEquals("Does Not Trail Past Open", expected, actual);
    }
}