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
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CancelPendingOrderByTicket/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

IntUnitTest<DefaultUnitTestRecord> *NoErrorsUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *ErrorsWhenCancelingDeletedOrderUnitTest;

int OnInit()
{
    NoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Errors", "Doesn't Return an Error When Cancelign Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    ErrorsWhenCancelingDeletedOrderUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Errors When Canceling Delete Order", "Returns Error When Trying To Cancel A Deleted Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, ErrorsWhenCancelingDeletedOrder);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NoErrorsUnitTest;
    delete ErrorsWhenCancelingDeletedOrderUnitTest;
}

void OnTick()
{
    NoErrorsUnitTest.Assert();
    ErrorsWhenCancelingDeletedOrderUnitTest.Assert();
}

int NoErrors(out int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = OrderHelper::CancelPendingOrderByTicket(ticket);
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int ErrorsWhenCancelingDeletedOrder(out bool &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(10);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);

        int errors = OrderHelper::CancelPendingOrderByTicket(ticket);
        if (errors == ERR_NO_ERROR)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        actual = ticket != EMPTY;
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return GetLastError();
}