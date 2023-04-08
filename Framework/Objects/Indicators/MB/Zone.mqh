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
    // --- Constructor / Destructor ---
    Zone(string symbol, int timeFrame, int mbNumber, int zoneNumber, int type, string description, datetime startDateTime,
         double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy);
    ~Zone();

    // --- Setters ---
    void WasRetrieved(bool wasRetrieved) { mWasRetrieved = wasRetrieved; }

    // --- Maintenance Methods ---
    void UpdateIndexes(int barIndex);
};

Zone::Zone(string symbol, int timeFrame, int mbNumber, int zoneNumber, int type, string description, datetime startDateTime,
           double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy)
{
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
    mWasRetrieved = false;

    mFurthestPointWasSet = false;
    mLowestConfirmationMBLowWithin = 0.0;
    mHighestConfirmationMBHighWithin = 0.0;

    mName = "Zone: " + IntegerToString(timeFrame) + "_" + IntegerToString(mNumber) + ", MB: " + IntegerToString(mMBNumber);
}

Zone::~Zone()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
}
