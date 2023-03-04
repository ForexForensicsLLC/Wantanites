//+------------------------------------------------------------------+
//|                                   CancelPendingOrderByTicket.mq4 |
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

const string Directory = "/UnitTests/Helpers/OrderHelper/CancelPendingOrderByTicket/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1sZqvQX9NmSYbs9fwOQtKx8du2mJbfied/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *NoErrorsUnitTest;

// https://drive.google.com/file/d/1CQd6HniMS8WAg8-amUh-R4BlKf1DaX-B/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ErrorsWhenCancelingDeletedOrderUnitTest;

int OnInit()
{
    NoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Errors", "Doesn't Return an Error When Cancelign Pending Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    ErrorsWhenCancelingDeletedOrderUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Errors When Canceling Delete Order", "Returns Error When Trying To Cancel A Deleted Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, ErrorsWhenCancelingDeletedOrder);

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
    ErrorsWhenCancelingDeletedOrderUnitTest.Assert(false);
}

int NoErrors(out int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        actual = OrderHelper::CancelPendingOrderByTicket(ticket);
        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}

int ErrorsWhenCancelingDeletedOrder(int &actual)
{
    int type = OP_BUYSTOP;
    double entryPrice = Ask + OrderHelper::PipsToRange(100);
    double stopLoss = Bid - OrderHelper::PipsToRange(100);

    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, 0, 0, clrNONE);
    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);

        actual = OrderHelper::CancelPendingOrderByTicket(ticket);
        return Results::UNIT_TEST_RAN;
    }

    return GetLastError();
}