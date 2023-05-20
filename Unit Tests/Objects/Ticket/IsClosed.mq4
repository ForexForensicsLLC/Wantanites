//+------------------------------------------------------------------+
//|                                                     IsClosed.mq4 |
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

const string Directory = "/UnitTests/Objects/Ticket/IsClosed/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

// https://drive.google.com/drive/folders/16O-qua0pRP9SlgSvyitIUGjUdFkn53by?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *IsClosedUnitTest;

// https://drive.google.com/drive/folders/1lzPp1RquzuTSb-8sD88Jzwkdb43Py3ne?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *IsNotClosedUnitTest;

int OnInit()
{
    IsClosedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Closed", "Should return true indicating that the ticket is closed",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, IsClosed);

    IsNotClosedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Not Closed", "Should return false indicating that the ticket is not closed",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, IsNotClosed);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete IsClosedUnitTest;
    delete IsNotClosedUnitTest;
}

void OnTick()
{
    IsClosedUnitTest.Assert();
    IsNotClosedUnitTest.Assert();
}

int IsClosed(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);
    ticket.Close();

    int isClosedError = ticket.IsClosed(actual);
    if (isClosedError != Errors::NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Close Time: " + IntegerToString(OrderCloseTime());

    return Results::UNIT_TEST_RAN;
}

int IsNotClosed(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);

    int isClosedError = ticket.IsClosed(actual);
    if (isClosedError != Errors::NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Close Time: " + IntegerToString(OrderCloseTime());

    ticket.Close();
    return Results::UNIT_TEST_RAN;
}