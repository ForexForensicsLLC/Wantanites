//+------------------------------------------------------------------+
//|                                                     IsActive.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Objects\Ticket.mqh>
#include <Wantanites\Framework\Trackers\MBTracker.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Ticket/IsActive/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

// https://drive.google.com/drive/folders/1T_hoaqMln0FfhKF7e0Z9wF70s7tjhFOp?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *MarketOrderIsActiveUnitTest;

// https://drive.google.com/drive/folders/17BIIYj7SA0S_IKZvjcIRBkX6ROv1zLWd?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *PendingOrderIsNotActiveUnitTest;

int OnInit()
{
    MarketOrderIsActiveUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Active", "Should Return True Indicating the ticket is active",
        NumberOfAsserts, 0, RecordErrors,
        true, MarketOrderIsActive);

    PendingOrderIsNotActiveUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Not Active", "Should Return False Indicating the ticket is not active",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, PendingOrderIsNotActive);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MarketOrderIsActiveUnitTest;
    delete PendingOrderIsNotActiveUnitTest;
}

void OnTick()
{
    MarketOrderIsActiveUnitTest.Assert();
    PendingOrderIsNotActiveUnitTest.Assert();
}

int MarketOrderIsActive(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);

    int selectError = ticket.SelectIfOpen("Testing If Activated");
    if (selectError != Errors::NO_ERROR)
    {
        return selectError;
    }

    ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Close Time: " + IntegerToString(OrderCloseTime());

    int activeError = ticket.IsActive(actual);
    if (activeError != Errors::NO_ERROR)
    {
        return activeError;
    }

    ticket.Close();
    delete ticket;

    return Results::UNIT_TEST_RAN;
}

int PendingOrderIsNotActive(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUYSTOP, 0.1, Ask + OrderHelper::PipsToRange(20), 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);

    int selectError = ticket.SelectIfOpen("Testing If Activated");
    if (selectError != Errors::NO_ERROR)
    {
        return selectError;
    }

    ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Close Time: " + IntegerToString(OrderCloseTime());

    int activeError = ticket.IsActive(actual);
    if (activeError != Errors::NO_ERROR)
    {
        return activeError;
    }

    ticket.Close();
    return Results::UNIT_TEST_RAN;
}