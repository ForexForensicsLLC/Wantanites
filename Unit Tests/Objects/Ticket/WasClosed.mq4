//+------------------------------------------------------------------+
//|                                                    WasClosed.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Objects\Ticket.mqh>
#include <WantaCapital\Framework\Trackers\MBTracker.mqh>

#include <WantaCapital\Framework\Helpers\SetupHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Ticket/WasClosed/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

// https://drive.google.com/drive/folders/1NqMV4i4-WSrD_uYKhVpwwpV-pkNKIHLR?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *WasClosedUnitTest;

// https://drive.google.com/drive/folders/1pGVpUDy-5kbpzFZjGyhIPULg0zGYRYEJ?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *WasNotClosedUnitTest;

int OnInit()
{
    WasClosedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Was Closed", "Should return true indicating that the ticket was closed",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, WasClosed);

    WasNotClosedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Was Not Closed", "Should return true indicating that the ticket was not closed",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, WasNotClosed);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete WasClosedUnitTest;
    delete WasNotClosedUnitTest;
}

void OnTick()
{
    WasClosedUnitTest.Assert();
    WasNotClosedUnitTest.Assert();
}

int WasClosed(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);

    bool wasClosed;
    int wasClosedError = ticket.WasClosed(wasClosed);
    if (wasClosedError != ERR_NO_ERROR)
    {
        return wasClosedError;
    }

    ticket.Close();
    bool newWasClosed;
    int newWasClosedError = ticket.WasClosed(newWasClosed);
    if (newWasClosedError != ERR_NO_ERROR)
    {
        return newWasClosedError;
    }

    int selectError = ticket.SelectIfClosed("Testing If Activated");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Close Time: " + TimeToStr(OrderCloseTime(), TIME_DATE | TIME_SECONDS);
    actual = wasClosed != newWasClosed && newWasClosed;

    delete ticket;
    return Results::UNIT_TEST_RAN;
}

int WasNotClosed(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    Ticket *ticket = new Ticket();

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Bid - OrderHelper::PipsToRange(50), 0, NULL, 0, 0, clrNONE);
    if (ticketNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ticket.SetNewTicket(ticketNumber);
    ut.PendingRecord.AdditionalInformation = "Ticket By Number: " + IntegerToString(ticketNumber);

    int selectError = ticket.SelectIfOpen("Testing If Activated");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    ut.PendingRecord.AdditionalInformation += "Ticket By Select: " + IntegerToString(OrderTicket()) + " Type: " + IntegerToString(OrderType()) + " Close Time: " + TimeToStr(OrderCloseTime(), TIME_DATE | TIME_SECONDS);

    bool wasClosed;
    int wasClosedError = ticket.WasClosed(wasClosed);
    if (wasClosedError != ERR_NO_ERROR)
    {
        return wasClosedError;
    }

    bool newWasClosed;
    int newWasClosedError = ticket.WasClosed(newWasClosed);
    if (newWasClosedError != ERR_NO_ERROR)
    {
        return newWasClosedError;
    }

    actual = wasClosed == newWasClosed && !newWasClosed;

    ticket.Close();
    delete ticket;
    return Results::UNIT_TEST_RAN;
}
