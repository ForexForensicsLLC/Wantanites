//+------------------------------------------------------------------+
//|                                    PlaceStopOrderOnBreakOfMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/PlaceStopOrderForBreakOfMB/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1ymrRwMMYEwfvkhNDcEbhQ8WcN0vG7qYw/view?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBCorrectOrderPlacementImagesUnitTest;

// https://drive.google.com/file/d/1OdCPQD_PAd21hNQ3G7dJWHGlMKNqSHgH/view?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBCorrectOrderPlacementImagesUnitTest;

// https://drive.google.com/file/d/1vRH6o0Ebe_33-6GmKJ42VYsCTD8eNttZ/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBNoErrorUnitTest;

// https://drive.google.com/file/d/1Jtp8-amf11E-TwAOl9NjyWEot9O1FIWn/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBNoErrorUnitTest;

// https://drive.google.com/file/d/1LSh4T8IBekHukoQll8U33f4ut6H64kAg/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *MBDoesNotExistErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBCorrectOrderPlacementImagesUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Break Of Bullish MB Images", "All Should Be Corect For Bullish Setups",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BullishMBCorrectOrderPlacementImages);

    BearishMBCorrectOrderPlacementImagesUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Break Of Bearish MB Images", "All Should Be Corect For Bearish Setups",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BearishMBCorrectOrderPlacementImages);

    BullishMBNoErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB No Errors", "Returns No Errors When Placing Stop Order For Break Of Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::NO_ERROR, BullishMBNoError);

    BearishMBNoErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB No Errors", "Returns No Errors When Placing Stop Order For Break Of Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::NO_ERROR, BearishMBNoError);

    MBDoesNotExistErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "MB Does Not Exist Error", "Returns No Errors When Placing Stop Order For Break Of Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::MB_DOES_NOT_EXIST, MBDoesNotExistError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBCorrectOrderPlacementImagesUnitTest;
    delete BearishMBCorrectOrderPlacementImagesUnitTest;

    delete BullishMBNoErrorUnitTest;
    delete BearishMBNoErrorUnitTest;

    delete MBDoesNotExistErrorUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBCorrectOrderPlacementImagesUnitTest.Assert();
    BearishMBCorrectOrderPlacementImagesUnitTest.Assert();

    BullishMBNoErrorUnitTest.Assert();
    BearishMBNoErrorUnitTest.Assert();

    MBDoesNotExistErrorUnitTest.Assert();
}

int CloseTicket(int &ticket)
{
    bool isPending = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isPending);
    if (pendingOrderError != Errors::NO_ERROR)
    {
        return pendingOrderError;
    }

    if (isPending)
    {
        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }
    }
    else
    {
        int orderSelectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Check Edit Stop Loss");
        if (orderSelectError != Errors::NO_ERROR)
        {
            return orderSelectError;
        }

        if (OrderType() == OP_BUY)
        {
            if (!OrderClose(ticket, OrderLots(), Bid, 0, clrNONE))
            {
                return GetLastError();
            }
        }
        else if (OrderType() == OP_SELL)
        {
            if (!OrderClose(ticket, OrderLots(), Ask, 0, clrNONE))
            {
                return GetLastError();
            }
        }
    }

    ticket = EMPTY;
    return Errors::NO_ERROR;
}

int PlaceOrder(int mbNumber, int &ticket, bool usePaddingAndSpread = true)
{
    int paddingPips = 0;
    int spreadPips = 0;

    if (usePaddingAndSpread)
    {
        paddingPips = 10;
        spreadPips = 10;
    }

    double riskPercent = 0.25;
    int magicNumber = 0;

    return OrderHelper::PlaceStopOrderForBreakOfMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
}

int BullishMBNoError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBNoErrorUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BullishMBNoErrorUnitTest.Directory());
    BullishMBNoErrorUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int ticket = EMPTY;
    actual = PlaceOrder(tempMBState.Number(), ticket);

    BullishMBNoErrorUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BullishMBNoErrorUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != Errors::NO_ERROR)
        {
            return closeTicketError;
        }
    }

    return Results::UNIT_TEST_RAN;
}

int BearishMBNoError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBNoErrorUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BearishMBNoErrorUnitTest.Directory());
    BearishMBNoErrorUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int ticket = EMPTY;
    actual = PlaceOrder(tempMBState.Number(), ticket);

    BearishMBNoErrorUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BearishMBNoErrorUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != Errors::NO_ERROR)
        {
            return closeTicketError;
        }
    }

    return Results::UNIT_TEST_RAN;
}

int MBDoesNotExistError(int &actual)
{

    MBDoesNotExistErrorUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(MBDoesNotExistErrorUnitTest.Directory());
    MBDoesNotExistErrorUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int ticket = EMPTY;
    actual = PlaceOrder(EMPTY, ticket);

    MBDoesNotExistErrorUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(MBDoesNotExistErrorUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != Errors::NO_ERROR)
        {
            return closeTicketError;
        }
    }

    return Results::UNIT_TEST_RAN;
}

int BullishMBCorrectOrderPlacementImages(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BullishMBCorrectOrderPlacementImagesUnitTest.Directory());
    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int ticket = EMPTY;
    int placeOrderError = PlaceOrder(tempMBState.Number(), ticket, false);
    if (placeOrderError != Errors::NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BullishMBCorrectOrderPlacementImagesUnitTest.Directory());

    if (ticket > 0)
    {
        int ticketError = CloseTicket(ticket);
        if (ticketError != Errors::NO_ERROR)
        {
            return ticketError;
        }
    }

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishMBCorrectOrderPlacementImages(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BearishMBCorrectOrderPlacementImagesUnitTest.Directory());
    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int ticket = EMPTY;
    int placeOrderError = PlaceOrder(tempMBState.Number(), ticket, false);
    if (placeOrderError != Errors::NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BearishMBCorrectOrderPlacementImagesUnitTest.Directory());

    if (ticket > 0)
    {
        int ticketError = CloseTicket(ticket);
        if (ticketError != Errors::NO_ERROR)
        {
            return ticketError;
        }
    }

    actual = true;
    return Results::UNIT_TEST_RAN;
}