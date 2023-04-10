//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\Indicators\MB\ZoneState.mqh>

class Zone : public ZoneState
{
public:
    Zone();           // only used for default constructor in ObjectList
    Zone(Zone &zone); // only here for copy constructor in ObjectList
    Zone(bool isPending, string symbol, int timeFrame, int mbNumber, int zoneNumber, int type, string description, datetime startDateTime,
         double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy, color zoneColor);
    ~Zone();

    void EndTime(datetime time) { mEndDateTime = time; }

    void UpdateDrawnObject();
};
Zone::Zone() {}

Zone::Zone(Zone &zone) {}

Zone::Zone(bool isPending, string symbol, int timeFrame, int mbNumber, int zoneNumber, int type, string description, datetime startDateTime,
           double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy, color zoneColor)
{
    mIsPending = isPending;
    mSymbol = symbol;
    mTimeFrame = timeFrame;

    mNumber = zoneNumber;
    mMBNumber = mbNumber;
    mType = type;
    mDescription = description;

    mHeight = 0.0;

    mStartDateTime = startDateTime;
    mEndDateTime = endDateTime;

    mEntryPrice = entryPrice;
    mExitPrice = exitPrice;

    mEntryOffset = entryOffset;

    mBrokenBy = brokenBy;
    mDrawn = false;
    mZoneColor = zoneColor;

    mFurthestPointWasSet = false;
    mLowestConfirmationMBLowWithin = 0.0;
    mHighestConfirmationMBHighWithin = 0.0;

    mName = "Zone" + IntegerToString(mType) + ": " + IntegerToString(timeFrame) + "_" + IntegerToString(mNumber) + ", MB: " + IntegerToString(mMBNumber);
}

Zone::~Zone()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
}

void Zone::UpdateDrawnObject()
{
    if (!mDrawn)
    {
        Draw();
    }
    else
    {
        ObjectSet(mName, OBJPROP_TIME1, mStartDateTime);
        ObjectSet(mName, OBJPROP_PRICE1, mEntryPrice);
        ObjectSet(mName, OBJPROP_TIME2, mEndDateTime);
        ObjectSet(mName, OBJPROP_PRICE2, mExitPrice);

        ChartRedraw();
    }
}