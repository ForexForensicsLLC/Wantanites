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
private:
    static string DateTimeToFilePathString(datetime dt);

public:
    static int TryTakeUnitTestScreenShot(string directory, out string &imageName);
    static int TryTakeOrderOpenScreenShot(int ticket, string directory, out string &imageName);
    static int TryTakeOrderCloseScreenShot(int ticket, string directory, out string &imageName);
};

static string ScreenShotHelper::DateTimeToFilePathString(datetime dt)
{
    return IntegerToString(TimeYear(dt)) + "-" +
           IntegerToString(TimeMonth(dt)) + "-" +
           IntegerToString(TimeDay(dt)) + "_" +
           IntegerToString(TimeHour(dt)) + "-" +
           IntegerToString(TimeMinute(dt)) + "-" +
           IntegerToString(TimeSeconds(dt));
}

static int ScreenShotHelper::TryTakeUnitTestScreenShot(string directory, out string &imageName)
{
    imageName = DateTimeToFilePathString(TimeCurrent()) + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, 2000, 800, ALIGN_RIGHT))
    {
        imageName = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}

static int ScreenShotHelper::TryTakeOrderOpenScreenShot(int ticket, string directory, out string &imageName)
{
    imageName = "";
    if (ticket == EMPTY)
    {
        return Errors::ERR_EMPTY_TICKET;
    }

    int orderSelectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Taking Entry Screen Shot");
    if (orderSelectError != ERR_NO_ERROR)
    {
        return orderSelectError;
    }

    imageName = DateTimeToFilePathString(OrderOpenTime()) + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, 2000, 800, ALIGN_RIGHT))
    {
        imageName = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}

static int ScreenShotHelper::TryTakeOrderCloseScreenShot(int ticket, string directory, out string &imageName)
{
    imageName = "";
    if (ticket == EMPTY)
    {
        return Errors::ERR_EMPTY_TICKET;
    }

    int orderSelectError = OrderHelper::SelectClosedOrderByTicket(ticket, "Taking Closed Screen Shot");
    if (orderSelectError != ERR_NO_ERROR)
    {
        return orderSelectError;
    }

    imageName = DateTimeToFilePathString(OrderCloseTime()) + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, 2000, 800, ALIGN_RIGHT))
    {
        imageName = "";
        return GetLastError();
    }

    return ERR_NO_ERROR;
}