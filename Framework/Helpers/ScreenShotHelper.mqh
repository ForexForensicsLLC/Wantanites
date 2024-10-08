//+------------------------------------------------------------------+
//|                                             ScreenShotHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>
#include <Wantanites\Framework\Constants\Errors.mqh>

class ScreenShotHelper
{
private:
    static string CurrentDateTimeToFilePathString();

public:
    static string TryTakeScreenShot(string directory, string suffix, int width, int height);

    static string TryTakeBeforeScreenShot(string directory, string suffix);
    static string TryTakeAfterScreenShot(string directory, string suffix);

    static int TryTakeMultiTimeFrameScreenShot(string directory, int secondChartTimeFrame, string &currentChartImageName, string &secondChartImageName);
};

static string ScreenShotHelper::CurrentDateTimeToFilePathString()
{
    MqlDateTime currentTime = DateTimeHelper::CurrentTime();

    return IntegerToString(currentTime.year) + "-" +
           IntegerToString(currentTime.mon) + "-" +
           IntegerToString(currentTime.day) + "_" +
           IntegerToString(currentTime.hour) + "-" +
           IntegerToString(currentTime.min) + "-" +
           IntegerToString(currentTime.sec);
}

static string ScreenShotHelper::TryTakeScreenShot(string directory, string suffix = "", int width = 2000, int height = 800)
{
    string imageName = CurrentDateTimeToFilePathString() + suffix + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, width, height, ALIGN_RIGHT))
    {
        int error = GetLastError();
        imageName = "Error: " + IntegerToString(error);
    }

    return imageName;
}

static string ScreenShotHelper::TryTakeBeforeScreenShot(string directory, string suffix = "")
{
    string imageName = CurrentDateTimeToFilePathString() + "_Before" + suffix + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, 2000, 800, ALIGN_RIGHT))
    {
        int error = GetLastError();
        imageName = "Error: " + IntegerToString(error);
    }

    return imageName;
}

static string ScreenShotHelper::TryTakeAfterScreenShot(string directory, string suffix = "")
{
    string imageName = CurrentDateTimeToFilePathString() + "_After" + suffix + ".png";
    string filePath = directory + "Images/" + imageName;

    if (!ChartScreenShot(ChartID(), filePath, 2000, 800, ALIGN_RIGHT))
    {
        int error = GetLastError();
        imageName = "Error: " + IntegerToString(error);
    }

    return imageName;
}

static int ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(string directory, int secondChartTimeFrame, string &currentChartImageName, string &secondChartImageName)
{
    bool foundChart = false;

    long secondChart = ChartFirst();
    long prevChart = ChartFirst();
    int i = 0;
    int limit = 100;

    while (i < limit)
    {
        // Have reached the end of the chart list
        if (secondChart < 0)
        {
            break;
        }

        if (ChartSymbol(secondChart) == Symbol() && ChartPeriod(secondChart) == secondChartTimeFrame)
        {
            foundChart = true;
            break;
        }

        prevChart = secondChart;
        secondChart = ChartNext(prevChart);

        i++;
    }

    if (!foundChart)
    {
        return Errors::SECOND_CHART_NOT_FOUND;
    }

    string dateTime = CurrentDateTimeToFilePathString();
    currentChartImageName = directory + "Images/" + dateTime + "_Period " + IntegerToString(Period()) + ".png";
    secondChartImageName = directory + "Images/" + dateTime + "_Period " + IntegerToString(secondChartTimeFrame) + ".png";

    if (!ChartScreenShot(ChartID(), currentChartImageName, 8000, 4400, ALIGN_RIGHT))
    {
        return GetLastError();
    }

    if (!ChartScreenShot(secondChart, secondChartImageName, 2000, 800, ALIGN_RIGHT))
    {
        return GetLastError();
    }

    return Errors::NO_ERROR;
}
