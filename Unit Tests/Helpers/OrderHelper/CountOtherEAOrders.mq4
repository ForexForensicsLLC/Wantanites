//+------------------------------------------------------------------+
//|                                           CountOtherEAOrders.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/CountOtherEAOrders/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

const int SetOneMagicNumberOne = 101;
const int SetOneMagicNumberTwo = 102;
const int SetOneMagicNumberThree = 103;
int SetOneMagicNumberArray[];

const int SetTwoMagicNumberOne = 201;
const int SetTwoMagicNumberTwo = 202;
const int SetTwoMagicNumberThree = 203;
int SetTwoMagicNumberArray[];

const int SetThreeMagicNumberOne = 301;
const int SetThreeMagicNumberTwo = 302;
const int SetThreeMagicNumberThree = 303;
int SetThreeMagicNumberArray[];

// https://drive.google.com/file/d/1NCUJsWNCxpCiGMCuF_6IAOk_iETIrAit/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ZeroOtherEAOrdersUnitTest;

// https://drive.google.com/file/d/1beM2NFiqMC16ZpDY0i3TJnF2G_4ufOC1/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *MultipleOrderesFromOneEAUnitTest;

// https://drive.google.com/file/d/15rjIQWd1GJLgAHJF-xP8tUDjJEFS5nPl/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *MultipleOrderesFromMultipleEAsUnitTest;

int OnInit()
{
    ArrayResize(SetOneMagicNumberArray, 3);
    SetOneMagicNumberArray[0] = SetOneMagicNumberOne;
    SetOneMagicNumberArray[1] = SetOneMagicNumberTwo;
    SetOneMagicNumberArray[2] = SetOneMagicNumberThree;

    ArrayResize(SetTwoMagicNumberArray, 3);
    SetTwoMagicNumberArray[0] = SetTwoMagicNumberOne;
    SetTwoMagicNumberArray[1] = SetTwoMagicNumberTwo;
    SetTwoMagicNumberArray[2] = SetTwoMagicNumberThree;

    ArrayResize(SetThreeMagicNumberArray, 3);
    SetThreeMagicNumberArray[0] = SetThreeMagicNumberOne;
    SetThreeMagicNumberArray[1] = SetThreeMagicNumberTwo;
    SetThreeMagicNumberArray[2] = SetThreeMagicNumberThree;

    ZeroOtherEAOrdersUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Zero Other EA Orders", "0 Should Be Returned After No Orders Are Placed",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        0, ZeroOtherEAOrders);

    MultipleOrderesFromOneEAUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Multiple Orders From One EA", "Should Return Multiple Orders",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        2, MultipleOrdersFromOneEA);

    MultipleOrderesFromMultipleEAsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Multiple Orders From Multiple EAs", "Should Return Orders From Multiple Differnt EAs",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        2, MultipleOrdersFromMultipleEAs);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete ZeroOtherEAOrdersUnitTest;
    delete MultipleOrderesFromOneEAUnitTest;
    delete MultipleOrderesFromMultipleEAsUnitTest;
}

void OnTick()
{
    ZeroOtherEAOrdersUnitTest.Assert();
    MultipleOrderesFromOneEAUnitTest.Assert();
    MultipleOrderesFromMultipleEAsUnitTest.Assert();
}

int ZeroOtherEAOrders(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T1 - " + 999, 999, 0, clrNONE);
    if (ticketOne < 0)
    {
        int error = GetLastError();
        Print("Error: ", error);

        return GetLastError();
    }

    actual = 1;
    int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(SetOneMagicNumberArray, actual);

    if (!OrderDelete(ticketOne, clrNONE))
    {
        return GetLastError();
    }

    if (otherEAOrdersErrors != ERR_NO_ERROR)
    {
        return otherEAOrdersErrors;
    }

    return Results::UNIT_TEST_RAN;
}

int MultipleOrdersFromOneEA(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T1 - " + SetTwoMagicNumberOne, SetTwoMagicNumberOne, 0, clrNONE);
    if (ticketOne < 0)
    {
        return GetLastError();
    }

    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T2 - " + SetTwoMagicNumberOne, SetTwoMagicNumberOne, 0, clrNONE);
    if (ticketTwo < 0)
    {
        OrderDelete(ticketOne, clrNONE);
        return GetLastError();
    }

    int ticketThree = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T2 - " + 999, 999, 0, clrNONE);
    if (ticketThree < 0)
    {
        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);

        return GetLastError();
    }

    actual = 0;

    int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(SetTwoMagicNumberArray, actual);

    if (!OrderDelete(ticketOne, clrNONE))
    {
        return GetLastError();
    }

    if (!OrderDelete(ticketTwo, clrNONE))
    {
        return GetLastError();
    }

    if (!OrderDelete(ticketThree, clrNONE))
    {
        return GetLastError();
    }

    if (otherEAOrdersErrors != ERR_NO_ERROR)
    {
        return otherEAOrdersErrors;
    }

    return Results::UNIT_TEST_RAN;
}

int MultipleOrdersFromMultipleEAs(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T1 - " + SetThreeMagicNumberOne, SetThreeMagicNumberOne, 0, clrNONE);
    if (ticketOne < 0)
    {
        return GetLastError();
    }

    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T2 - " + SetThreeMagicNumberTwo, SetThreeMagicNumberTwo, 0, clrNONE);
    if (ticketTwo < 0)
    {
        OrderDelete(ticketOne, clrNONE);
        return GetLastError();
    }

    int ticketThree = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, "T2 - " + 999, 999, 0, clrNONE);
    if (ticketThree < 0)
    {
        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);

        return GetLastError();
    }

    actual = 0;
    int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(SetThreeMagicNumberArray, actual);

    if (!OrderDelete(ticketOne, clrNONE))
    {
        return GetLastError();
    }

    if (!OrderDelete(ticketTwo, clrNONE))
    {
        return GetLastError();
    }

    if (!OrderDelete(ticketThree, clrNONE))
    {
        return GetLastError();
    }

    if (otherEAOrdersErrors != ERR_NO_ERROR)
    {
        return otherEAOrdersErrors;
    }

    return Results::UNIT_TEST_RAN;
}
