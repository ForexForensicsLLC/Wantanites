//+------------------------------------------------------------------+
//|                                                 WasActivated.mq4 |
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

const string Directory = "/UnitTests/Objects/Ticket/WasActivated/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

// https://drive.google.com/drive/folders/16qibAJKcseaOkDspUYtbGGPohk9Ruse-?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *WasActivatedUnitTest;

// https://drive.google.com/drive/folders/1P_OR_Au74DWujtdaAPX2t_HrvSQ3AhB5?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *WasNotActivatedUnitTest;

int OnInit()
{
    WasActivatedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Was Activated", "Should Return True Indicating the ticket is active",
        NumberOfAsserts, 0, RecordErrors,
        true, WasActivated);

    WasNotActivatedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Was Not Activated", "Should Return False Indicating the ticket is not active",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, WasNotActivated);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete WasActivatedUnitTest;
    delete WasNotActivatedUnitTest;
}

void OnTick()
{
    // WasActivatedUnitTest.Assert();
    WasNotActivatedUnitTest.Assert();
}

void SetVariables(Ticket *&ticket, double &entryPrice, bool &activated, bool &reset)
{
    if (reset)
    {
        if (ticket.Number() != EMPTY)
        {
            ticket.Close();
            ticket.SetNewTicket(EMPTY);
        }

        entryPrice = 0.0;
        activated = false;
        reset = false;
    }

    if (ticket.Number() != EMPTY && entryPrice > 0 && OrderHelper::RangeToPips((entryPrice - Ask)) > 20)
    {
        reset = true;
    }

    if (activated && OrderType() < 2)
    {
        reset = true;
    }

    if (ticket.Number() == EMPTY)
    {
        entryPrice = Ask + OrderHelper::PipsToRange(15);
        int ticketNumber = OrderSend(Symbol(), OP_BUYSTOP, 0.1, entryPrice, 0, 0, 0, NULL, 0, 0, clrNONE);
        if (ticketNumber < 0)
        {
            return;
        }

        ticket.SetNewTicket(ticketNumber);
        reset = false;
    }
}

int WasActivated(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static Ticket *ticket = new Ticket();
    static double entryPrice = 0.0;
    static bool activated = false;
    static bool reset = false;

    SetVariables(ticket, entryPrice, activated, reset);

    int selectError = ticket.SelectIfOpen("Testing If Activated");
    if (selectError != Errors::NO_ERROR)
    {
        reset = true;
        return selectError;
    }

    if (!activated && OrderType() < 2)
    {
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
        ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Open Time: " + IntegerToString(OrderOpenTime());

        ticket.WasActivated(actual);
        reset = true;
        return Results::UNIT_TEST_RAN;
    }

    ticket.WasActivated(activated);
    return Results::UNIT_TEST_DID_NOT_RUN;
}

int WasNotActivated(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static Ticket *ticket = new Ticket();
    static double entryPrice = 0.0;
    static bool activated = false;
    static bool reset = false;

    SetVariables(ticket, entryPrice, activated, reset);

    int selectError = ticket.SelectIfOpen("Testing If Activated");
    if (selectError != Errors::NO_ERROR)
    {
        reset = true;
        return selectError;
    }

    if (OrderType() >= 2)
    {
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
        ut.PendingRecord.AdditionalInformation = "Type: " + IntegerToString(OrderType()) + " Open Time: " + IntegerToString(OrderOpenTime());

        ticket.WasActivated(actual);
        reset = true;
        return Results::UNIT_TEST_RAN;
    }

    reset = true;
    return Results::UNIT_TEST_DID_NOT_RUN;
}
