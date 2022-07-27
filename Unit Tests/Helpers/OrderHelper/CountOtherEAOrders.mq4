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
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CountOtherEAOrders/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;

const int MagicNumberOne = 001;
const int MagicNumberTwo = 002;
const int MagicNumberThree = 003;

int MagicNumberArray[];

int OnInit()
{
    ArrayResize(MagicNumberArray, 3);

    MagicNumberArray[0] = MagicNumberOne;
    MagicNumberArray[1] = MagicNumberTwo;
    MagicNumberArray[2] = MagicNumberThree;

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete zeroOtherEAOrdersUnitTest;
    delete multipleOrderesFromOneEAUnitTest;
    delete multipleOrderesFromMultipleEAsUnitTest;
}

void OnTick()
{
    ZeroOtherEAOrders();
    MultipleOrdersFromOneEA();
    MultipleOrdersFromMultipleEAs();
}

UnitTest<DefaultUnitTestRecord> *zeroOtherEAOrdersUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void ZeroOtherEAOrders()
{
    const int expected = 0;
    int actual = 1;

    int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
    if (otherEAOrdersErrors != ERR_NO_ERROR)
    {
        return;
    }

    zeroOtherEAOrdersUnitTest.addTest(__FUNCTION__);
    zeroOtherEAOrdersUnitTest.assertEquals("Zero Orders From Other EAs", expected, actual);
}

UnitTest<DefaultUnitTestRecord> *multipleOrderesFromOneEAUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void MultipleOrdersFromOneEA()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {
        const int expected = 2;
        int actual;

        int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
        if (otherEAOrdersErrors != ERR_NO_ERROR)
        {
            return;
        }

        multipleOrderesFromOneEAUnitTest.addTest(__FUNCTION__);
        multipleOrderesFromOneEAUnitTest.assertEquals("Multiple Orders From One EA", expected, actual);

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *multipleOrderesFromMultipleEAsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void MultipleOrdersFromMultipleEAs()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticketOne = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberOne, 0, clrNONE);
    int ticketTwo = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, MagicNumberTwo, 0, clrNONE);
    if (ticketOne > 0 && ticketTwo > 0)
    {

        const int expected = 2;
        int actual;

        int otherEAOrdersErrors = OrderHelper::CountOtherEAOrders(MagicNumberArray, actual);
        if (otherEAOrdersErrors != ERR_NO_ERROR)
        {
            return;
        }

        multipleOrderesFromMultipleEAsUnitTest.addTest(__FUNCTION__);
        multipleOrderesFromMultipleEAsUnitTest.assertEquals("Multiple Orders From Multiple EAs", expected, actual);

        OrderDelete(ticketOne, clrNONE);
        OrderDelete(ticketTwo, clrNONE);
    }
}
