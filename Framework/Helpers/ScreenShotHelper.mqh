//+------------------------------------------------------------------+
//|                                             ScreenShotHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Constants\Errors.mqh>

class ScreenShotHelper
{
public:
    static int TryTakeUnitTestScreenShot(string directory, out string &imageFilePath);
    static int TryTakeOrderOpenScreenShot(int ticket, string directory, out string &imageFilePath);
    static int TryTakeOrderCloseScreenShot(int ticket, string directory, out string &imageFilePath);
};

static int ScreenShotHelper::TryTakeUnitTestScreenShot(string directory, out string &imageFilePath)
{
    imageFilePath = directory + "/Images/" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
    if (!ChartScreenShot(ChartID(), imageFilePath, 2000, 800, ALIGN_RIGHT))
    {
        imageFilePath = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}

static int ScreenShotHelper::TryTakeOrderOpenScreenShot(int ticket, string directory, out string &imageFilePath)
{
    imageFilePath = "";
    if (ticket == EMPTY)
    {
        return Errors::ERR_EMPTY_TICKET;
    }

    int orderSelectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Taking Entry Screen Shot");
    if (orderSelectError != ERR_NO_ERROR)
    {
        return orderSelectError;
    }

    imageFilePath = directory + "/Images/" + TimeToString(OrderOpenTime(), TIME_DATE | TIME_SECONDS);
    if (!ChartScreenShot(ChartID(), imageFilePath, 2000, 800, ALIGN_RIGHT))
    {
        imageFilePath = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}

static int ScreenShotHelper::TryTakeOrderCloseScreenShot(int ticket, string directory, out string &imageFilePath)
{
    imageFilePath = "";
    if (ticket == EMPTY)
    {
        return Errors::ERR_EMPTY_TICKET;
    }

    int orderSelectError = OrderHelper::SelectClosedOrderByTicket(ticket, "Taking Closed Screen Shot");
    if (orderSelectError != ERR_NO_ERROR)
    {
        return orderSelectError;
    }

    imageFilePath = directory + "/Images/" + TimeToString(OrderCloseTime(), TIME_DATE | TIME_SECONDS);
    if (!ChartScreenShot(ChartID(), imageFilePath, 2000, 800, ALIGN_RIGHT))
    {
        imageFilePath = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}