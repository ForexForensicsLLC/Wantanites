//+------------------------------------------------------------------+
//|                          PlaceStopOrderOnMostRecentPendingMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/PlaceStopOrderForPendingMBValidation/";
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

// https://drive.google.com/file/d/1AQevi-9cTLIGgFjn0vjDRSU2fSq3J1zQ/view?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBCorrectOrderPlacementImagesUnitTest;

// https://drive.google.com/file/d/18qJHbaj_CzS5bdTZL-fZihM-AROW9uzs/view?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBCorrectOrderPlacementImagesUnitTest;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBNoOneThirtyErrorsUnitTest;
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBNoOneThirtyErrorsUnitTest;

// https://drive.google.com/file/d/1ul0PMUgyxeBTBhtZTJy3lzI00JZHLU1D/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBNoErrorUnitTest;

// https://drive.google.com/file/d/1hgMOcKn9QBLMI6q6CxqjKC5ggoQHQ3Wl/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBNoErrorUnitTest;

// https://drive.google.com/file/d/17kYDMJXLf8DEK_okKyKcZWDxVuenUKs7/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *NotMostRecentMBErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBCorrectOrderPlacementImagesUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Pending Bullish MB Images", "All Should Be Corect For Bullish Setups",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BullishMBCorrectOrderPlacementImages);

    BearishMBCorrectOrderPlacementImagesUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Pending Bearish MB Images", "All Should Be Corect For Bearish Setups",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BearishMBCorrectOrderPlacementImages);

    BullishMBNoOneThirtyErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB No 130 Errors", "Should Not Return A 130 - Invalid Stops Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        130, BullishMBNoOneThirtyErrors);

    BearishMBNoOneThirtyErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB No 130 Errors", "Should Not Return A 130 - Invalid Stops Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        130, BearishBNoOneThirtyErrors);

    BullishMBNoErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB No Errors", "Places Stop Order On Most Recent Bullish MB Without Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoError);

    BearishMBNoErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB No Errors", "Places Stop Order On Most Recent Bearish MB Without Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoError);

    NotMostRecentMBErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Not Most Recent MB Error", "Returns An Error When Trying To Place A Stop Order Not On The Most Recent MB",
        NumberOfAsserts, AssertCooldown, false, RecordErrors,
        ExecutionErrors::MB_IS_NOT_MOST_RECENT, NotMostRecentMBError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBCorrectOrderPlacementImagesUnitTest;
    delete BearishMBCorrectOrderPlacementImagesUnitTest;

    delete BullishMBNoOneThirtyErrorsUnitTest;
    delete BearishMBNoOneThirtyErrorsUnitTest;

    delete BullishMBNoErrorUnitTest;
    delete BearishMBNoErrorUnitTest;
    delete NotMostRecentMBErrorUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBCorrectOrderPlacementImagesUnitTest.Assert();
    BearishMBCorrectOrderPlacementImagesUnitTest.Assert();

    // BullishMBNoOneThirtyErrorsUnitTest.Assert(false);
    // BearishMBNoOneThirtyErrorsUnitTest.Assert(false);

    BullishMBNoErrorUnitTest.Assert();
    BearishMBNoErrorUnitTest.Assert();

    NotMostRecentMBErrorUnitTest.Assert();
}

int CloseTicket(int &ticket)
{
    bool isPending = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isPending);
    if (pendingOrderError != ERR_NO_ERROR)
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
        if (orderSelectError != ERR_NO_ERROR)
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
    return ERR_NO_ERROR;
}

int CheckMostRecentPendingMB(int type, string &info)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    if (tempMBState.Type() != type)
    {
        return EMPTY;
    }

    int retracementIndex = EMPTY;
    if (type == OP_BUY)
    {
        if (!MBT.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return EMPTY;
        }
    }
    else if (type == OP_SELL)
    {
        if (!MBT.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return EMPTY;
        }
    }

    if (retracementIndex == EMPTY)
    {
        return EMPTY;
    }

    return tempMBState.Number();
}

int PlaceStopOrder(int setupMBNumber, out int &ticket, bool usePaddingAndSpread = true)
{
    ticket = -1;
    int paddingPips = 0;
    int spreadPips = 0;

    if (usePaddingAndSpread)
    {
        paddingPips = 10;
        spreadPips = 10;
    }

    const double riskPercent = 0.25;
    const int magicNumber = 0;

    return OrderHelper::PlaceStopOrderForPendingMBValidation(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);
}

int PlaceStoporderOnMostRecentPendingMB(int type, out int &ticket, out string &info, bool usePaddingAndSpread = true)
{
    int mbNumber = CheckMostRecentPendingMB(type, info);
    if (mbNumber == EMPTY)
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    return PlaceStopOrder(mbNumber, ticket, usePaddingAndSpread);
}

int BullishMBNoOneThirtyErrors(int &actual)
{
    int ticket = -1;
    int type = OP_BUY;
    string additionalInfo = "";

    BullishMBNoOneThirtyErrorsUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BullishMBNoOneThirtyErrorsUnitTest.Directory());
    BullishMBNoOneThirtyErrorsUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo);
    if (error == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBNoOneThirtyErrorsUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BullishMBNoOneThirtyErrorsUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = error;
    return Results::UNIT_TEST_RAN;
}

int BearishBNoOneThirtyErrors(int &actual)
{
    int ticket = -1;
    int type = OP_SELL;
    string additionalInfo = "";

    BearishMBNoOneThirtyErrorsUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BearishMBNoOneThirtyErrorsUnitTest.Directory());
    BearishMBNoOneThirtyErrorsUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo);
    if (error == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBNoOneThirtyErrorsUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BearishMBNoOneThirtyErrorsUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = error;
    return Results::UNIT_TEST_RAN;
}

int BullishMBNoError(int &actual)
{
    int ticket = -1;
    int type = OP_BUY;
    string additionalInfo = "";

    BullishMBNoErrorUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BullishMBNoErrorUnitTest.Directory());
    BullishMBNoErrorUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo);
    if (error == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBNoErrorUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BullishMBNoErrorUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = error;
    return Results::UNIT_TEST_RAN;
}

int BearishMBNoError(int &actual)
{
    int ticket = -1;
    int type = OP_SELL;
    string additionalInfo = "";

    BearishMBNoErrorUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BearishMBNoErrorUnitTest.Directory());
    BearishMBNoErrorUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo);
    if (error == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBNoErrorUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BearishMBNoErrorUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = error;
    return Results::UNIT_TEST_RAN;
}

int NotMostRecentMBError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(2, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int ticket = -1;
    actual = PlaceStopOrder(tempMBState.Number(), ticket);

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    return Results::UNIT_TEST_RAN;
}

int BullishMBCorrectOrderPlacementImages(bool &actual)
{
    int ticket = -1;
    int type = OP_BUY;
    string additionalInfo = "";

    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BullishMBCorrectOrderPlacementImagesUnitTest.Directory());
    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo, false);
    if (error != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BullishMBCorrectOrderPlacementImagesUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishMBCorrectOrderPlacementImages(bool &actual)
{
    int ticket = -1;
    int type = OP_SELL;
    string additionalInfo = "";

    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(BearishMBCorrectOrderPlacementImagesUnitTest.Directory());
    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket, additionalInfo, false);
    if (error != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishMBCorrectOrderPlacementImagesUnitTest.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(BearishMBCorrectOrderPlacementImagesUnitTest.Directory());

    if (ticket > 0)
    {
        int closeTicketError = CloseTicket(ticket);
        if (closeTicketError != ERR_NO_ERROR)
        {
            return closeTicketError;
        }
    }

    actual = true;
    return Results::UNIT_TEST_RAN;
}