//+------------------------------------------------------------------+
//|                                           CountOtherEAOrders.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CountOtherEAOrders/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

const int MagicNumberOne = 001;
const int MagicNumberTwo = 002;
const int MagicNumberThree = 003;

int MagicNumberArray[];

IntUnitTest<DefaultUnitTestRecord> *ZeroOtherEAOrdersUnitTest;
IntUnitTest<DefaultUnitTestRecord> *MultipleOrderesFromOneEAUnitTest;
IntUnitTest<DefaultUnitTestRecord> *MultipleOrderesFromMultipleEAsUnitTest;

int OnInit()
{
    ArrayResize(MagicNumberArray, 3);

    MagicNumberArray[0] = MagicNumberOne;
    MagicNumberArray[1] = MagicNumberTwo;
    MagicNumberArray[2] = MagicNumberThree;

    ZeroOtherEAOrdersUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Zero Othe EA Orders", "0 Should Be Returned After No Orders Are Placed",
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
    actual = 1;

    int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
    if (otherEAOrdersErrors != ERR_NO_ERROR)
    {
        return otherEAOrdersErrors;
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}

int MultipleOrdersFromOneEA(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {
        actual = 0;

        int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
        if (otherEAOrdersErrors != ERR_NO_ERROR)
        {
            return otherEAOrdersErrors;
        }

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);

        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int MultipleOrdersFromMultipleEAs(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberTwo, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {
        actual = 0;

        int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
        if (otherEAOrdersErrors != ERR_NO_ERROR)
        {
            return otherEAOrdersErrors;
        }

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);

        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return GetLastError();
}
