//+------------------------------------------------------------------+
//|                                   CancelPendingOrderByTicket.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/CancelPendingOrderByTicket/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete noErrorsUnitTest;
    delete errorsWhenCancelingDeletedOrder;
}

void OnTick()
{
    NoErrors();
    ErrorsWhenCancelingDeletedOrder();
}

UnitTest<DefaultUnitTestRecord> *noErrorsUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void NoErrors()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        int expected = ERR_NO_ERROR;
        int actual = OrderHelper::CancelPendingOrderByTicket(ticket);

        noErrorsUnitTest.addTest(__FUNCTION__);
        noErrorsUnitTest.assertEquals("Cancel Pending Order By Ticket No Errors", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *errorsWhenCancelingDeletedOrder = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void ErrorsWhenCancelingDeletedOrder()
{
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);

        int errors = OrderHelper::CancelPendingOrderByTicket(ticket);
        if (errors == ERR_NO_ERROR)
        {
            return;
        }

        bool expected = true;
        bool actual = ticket != EMPTY;

        errorsWhenCancelingDeletedOrder.addTest(__FUNCTION__);
        errorsWhenCancelingDeletedOrder.assertEquals("Cancel Pending Order When Already Deleted Errors", expected, actual);
    }
}