//+------------------------------------------------------------------+
//|                                           CandleStickPattern.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>

class CandleStickPatternTracker
{
private:
    int mBarsCalculated;
    bool mHasSetup;
    bool mDraw;

    bool mTrackBullishSignalCandle;
    bool mTrackBearishSignalCandle;

    bool mTrackBullishMalcom;
    bool mTrackBearishMalcom;

    bool mTrackBullishEngulfing;
    bool mTrackBearishEngulfing;

    bool mTrackBullishRun;
    bool mTrackerBearishRun;

    bool mTrackHammerCandle;
    bool mTrackShootingStarCandle;

    bool mTrackEURejection;

    bool mTrackDistribution;
    datetime mDistributionAutomaticRally;
    datetime mDistributionSignOfWeaknessStart;
    datetime mDistributionSignOfWeaknessEnd;
    int mDistributionUpThrustCount;
    bool mDistributionHasLPSY;

    bool mTrackAccumulation;
    datetime mAccumulationAutomaticRally;
    datetime mAccumulationSignOfStrengthStart;
    datetime mAccumulationSignOfStrengthEnd;
    int mAccumulationUpThrustCount;
    bool mAccumulationHasLPS;

    void
    Calculate(int &barIndex);
    void Draw(int barIndex, color clr);

public:
    CandleStickPatternTracker(bool draw);
    ~CandleStickPatternTracker();

    bool HasSetup();

    void TrackBullishSignalCandle(bool track);
    void TrackBearishSignalCandle(bool track);

    void TrackBullishMalcom(bool track);
    void TrackBearishMalcom(bool track);

    void TrackBullishEngulfing(bool track);
    void TrackBearishEngulfing(bool track);

    void TrackBullishRun(bool track);
    void TrackBearishRun(bool track);

    void TrackHammerCandle(bool track);
    void TrackShootingStarCandle(bool track);

    void TrackEURejection(bool track);

    void TrackDistribution(bool track);
    void ResetDistribution();
    bool DistributionHasLPSY();
    datetime DistributionSignOfWeaknessStart();

    void TrackAccumulation(bool track);
    void ResetAccumulation();

    void
    Update();
};

CandleStickPatternTracker::CandleStickPatternTracker(bool draw)
{
    mBarsCalculated = 0;
    mHasSetup = false;
    mDraw = draw;

    mTrackBullishSignalCandle = false;
    mTrackBearishSignalCandle = false;

    mTrackBullishMalcom = false;
    mTrackBearishMalcom = false;

    mTrackBullishEngulfing = false;
    mTrackBearishEngulfing = false;

    mTrackBullishRun = false;
    mTrackerBearishRun = false;

    mTrackHammerCandle = false;
    mTrackShootingStarCandle = false;

    mTrackEURejection = false;

    mTrackDistribution = false;
    mDistributionAutomaticRally = EMPTY;
    mDistributionSignOfWeaknessStart = EMPTY;
    mDistributionSignOfWeaknessEnd = EMPTY;
    mDistributionUpThrustCount = 0;
    mDistributionHasLPSY = false;

    mTrackAccumulation = false;
    mAccumulationAutomaticRally = EMPTY;
    mAccumulationSignOfStrengthStart = EMPTY;
    mAccumulationSignOfStrengthEnd = EMPTY;
    mAccumulationUpThrustCount = 0;
    mAccumulationHasLPS = false;
}

CandleStickPatternTracker::~CandleStickPatternTracker()
{
    ObjectsDeleteAll(ChartID(), "CandleStickPattern");
}

void CandleStickPatternTracker::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int barIndex = currentBars - mBarsCalculated;

    if (barIndex <= 0)
    {
        return;
    }

    while (barIndex > 0)
    {
        Calculate(barIndex);

        barIndex -= 1;
    }

    mBarsCalculated = currentBars;
}

void CandleStickPatternTracker::Calculate(int &barIndex)
{
    if (mTrackBullishSignalCandle)
    {
        // has to be bullish and at least 70% body
        if (Close[barIndex] > Open[barIndex] && (Close[barIndex] - Open[barIndex]) > (0.7 * (High[barIndex] - Low[barIndex])))
        {
            // previous has to be bullish and liquidate the candle before it
            if (Close[barIndex + 1] > Open[barIndex + 1] && Open[barIndex + 1] > Close[barIndex + 2] && Low[barIndex + 1] < Low[barIndex + 2])
            {
                // 2 ago has to be bearish
                if (Close[barIndex + 2] < Open[barIndex + 2])
                {
                    mHasSetup = true;
                    if (mDraw)
                    {
                        Draw(barIndex, clrYellow);
                    }

                    return;
                }
            }
        }
    }

    if (mTrackBearishSignalCandle)
    {
        // has to be bearish and at least 70% body
        if (Close[barIndex] < Open[barIndex] && (Open[barIndex] - Close[barIndex]) > (0.7 * (High[barIndex] - Low[barIndex])))
        {
            // previous has to be bearish and liquidate the candle before it
            if (Close[barIndex + 1] < Open[barIndex + 1] && Open[barIndex + 1] < Close[barIndex + 2] && High[barIndex + 1] > High[barIndex + 2])
            {
                // 2 ago has to be bullish
                if (Close[barIndex + 2] > Open[barIndex + 2])
                {
                    mHasSetup = true;
                    if (mDraw)
                    {
                        Draw(barIndex, clrPurple);
                    }

                    return;
                }
            }
        }
    }

    if (mTrackBullishMalcom)
    {
        // 3rd previous must be bearish

        // 2nd previous must be within the 3rd
        if (MathMin(Open[barIndex + 2], Close[barIndex + 2]) > Low[barIndex + 3] && High[barIndex + 2] < High[barIndex + 3])
        {
            // previous must be a bullish candle that clsoed above the middle candle
            if (Close[barIndex + 1] > Open[barIndex + 1] && Close[barIndex + 1] > High[barIndex + 2])
            {
                mHasSetup = true;
                if (mDraw)
                {
                    Draw(barIndex, clrYellow);
                }

                return;
            }
        }
    }

    if (mTrackBearishMalcom)
    {
        // 3rd previous must be bullish

        // 2nd previous must be within the 3rd
        if (MathMax(Open[barIndex + 2], Close[barIndex + 2]) < High[barIndex + 3] && Low[barIndex + 2] > Low[barIndex + 3])
        {
            // previous must be a bearish candle that clsoed above the middle candle
            if (Close[barIndex + 1] < Open[barIndex + 1] && Close[barIndex + 1] < Low[barIndex + 2])
            {
                mHasSetup = true;
                if (mDraw)
                {
                    Draw(barIndex, clrPurple);
                }

                return;
            }
        }
    }

    if (mTrackBullishEngulfing)
    {
        if (Close[barIndex] > Open[barIndex] && MathMin(Open[barIndex + 1], Close[barIndex + 1]) >= Open[barIndex] && High[barIndex + 1] < Close[barIndex])
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrBlack);
            }

            return;
        }
    }

    if (mTrackBearishEngulfing)
    {
        if (Close[barIndex] < Open[barIndex] && MathMax(Open[barIndex + 1], Close[barIndex + 1]) <= Open[barIndex] && Low[barIndex + 1] > Close[barIndex])
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrWhite);
            }

            return;
        }
    }

    if (mTrackBullishRun)
    {
        if (Close[barIndex + 2] > Open[barIndex + 2] && Close[barIndex + 1] > Open[barIndex + 1] && Close[barIndex] > Open[barIndex])
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrYellow);
            }

            return;
        }
    }

    if (mTrackBullishRun)
    {
        if (Close[barIndex + 2] < Open[barIndex + 2] && Close[barIndex + 1] < Open[barIndex + 1] && Close[barIndex] < Open[barIndex])
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrPurple);
            }

            return;
        }
    }

    if (mTrackHammerCandle)
    {
        if (SetupHelper::HammerCandleStickPattern(Symbol(), Period(), barIndex))
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrYellow);
            }

            return;
        }
    }

    if (mTrackShootingStarCandle)
    {
        if (SetupHelper::ShootingStarCandleStickPattern(Symbol(), Period(), barIndex))
        {
            mHasSetup = true;
            if (mDraw)
            {
                Draw(barIndex, clrPurple);
            }

            return;
        }
    }

    if (mTrackEURejection)
    {
        double minPercentChange = 0.25;
        double percentChanged = (iOpen(Symbol(), Period(), barIndex) - iClose(Symbol(), Period(), barIndex)) / iOpen(Symbol(), Period(), barIndex);

        if (MathAbs(percentChanged) >= (minPercentChange / 100))
        {
            Draw(barIndex, clrBlack);
        }
    }

    if (mTrackDistribution)
    {
        if (mDistributionAutomaticRally == EMPTY)
        {
            if (/*iOpen(Symbol(), Period(), barIndex + 1) < iClose(Symbol(), Period(), barIndex + 1) &&*/
                iOpen(Symbol(), Period(), barIndex) > iClose(Symbol(), Period(), barIndex))
            {
                // Draw(barIndex, clrRed);
                mDistributionAutomaticRally = iTime(Symbol(), Period(), barIndex);
            }
        }
        else
        {
            if (mDistributionSignOfWeaknessStart == EMPTY)
            {
                if (iOpen(Symbol(), Period(), barIndex) > iClose(Symbol(), Period(), barIndex) && mDistributionUpThrustCount > 0)
                {
                    // Draw(barIndex, clrYellow);
                    mDistributionSignOfWeaknessStart = iTime(Symbol(), Period(), barIndex);
                }
                else if (iOpen(Symbol(), Period(), barIndex) > iClose(Symbol(), Period(), barIndex) && mDistributionUpThrustCount <= 0)
                {
                    ResetDistribution();
                    barIndex += 1;
                }
                else if (iOpen(Symbol(), Period(), barIndex) < iClose(Symbol(), Period(), barIndex) &&
                         iHigh(Symbol(), Period(), barIndex) > iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionAutomaticRally)))
                {
                    mDistributionUpThrustCount += 1;
                }
            }
            else
            {
                if (iHigh(Symbol(), Period(), barIndex) > iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessStart)))
                {
                    // Print("+BarIndex: ", barIndex, ", AR: ", iBarShift(Symbol(), Period(), mDistributionAutomaticRally), ", UT Count: ", mDistributionUpThrustCount, ", SOWS: ", iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessStart));
                    barIndex += (iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessStart) - barIndex + 1);
                    ResetDistribution();

                    return;
                }

                if (mDistributionSignOfWeaknessEnd == EMPTY)
                {
                    mDistributionSignOfWeaknessEnd = iTime(Symbol(), Period(), barIndex);
                }
                else
                {
                    if (!mDistributionHasLPSY && iLow(Symbol(), Period(), barIndex) < iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessEnd)))
                    {
                        // barIndex += (iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessStart) - barIndex + 1);
                        // ResetDistribution();
                        mDistributionSignOfWeaknessEnd = iTime(Symbol(), Period(), barIndex);
                        // Draw(barIndex, clrBlue);
                    }
                    else if (!mDistributionHasLPSY && iLow(Symbol(), Period(), barIndex) < iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionAutomaticRally)))
                    {
                        barIndex += (iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessStart) - barIndex + 1);
                        ResetDistribution();
                    }
                    else if (!mDistributionHasLPSY && iLow(Symbol(), Period(), barIndex) > iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionSignOfWeaknessEnd)))
                    {
                        // Draw(barIndex, clrBlue);
                        mDistributionHasLPSY = true;
                    }
                    else if (mDistributionHasLPSY && iLow(Symbol(), Period(), barIndex) < iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mDistributionAutomaticRally)))
                    {
                        Draw(barIndex, clrPurple);
                        ResetDistribution();
                    }
                }
            }
        }
    }

    if (mTrackAccumulation)
    {
        if (mAccumulationAutomaticRally == EMPTY)
        {
            if (/*iOpen(Symbol(), Period(), barIndex + 1) < iClose(Symbol(), Period(), barIndex + 1) &&*/
                iOpen(Symbol(), Period(), barIndex) < iClose(Symbol(), Period(), barIndex))
            {
                // Draw(barIndex, clrRed);
                mAccumulationAutomaticRally = iTime(Symbol(), Period(), barIndex);
            }
        }
        else
        {
            if (mAccumulationSignOfStrengthStart == EMPTY)
            {
                if (iOpen(Symbol(), Period(), barIndex) < iClose(Symbol(), Period(), barIndex) && mAccumulationUpThrustCount > 0)
                {
                    // Draw(barIndex, clrYellow);
                    mAccumulationSignOfStrengthStart = iTime(Symbol(), Period(), barIndex);
                }
                else if (iOpen(Symbol(), Period(), barIndex) < iClose(Symbol(), Period(), barIndex) && mAccumulationUpThrustCount <= 0)
                {
                    ResetAccumulation();
                    barIndex += 1;
                }
                else if (iOpen(Symbol(), Period(), barIndex) > iClose(Symbol(), Period(), barIndex) &&
                         iLow(Symbol(), Period(), barIndex) < iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationAutomaticRally)))
                {
                    mAccumulationUpThrustCount += 1;
                }
            }
            else
            {
                if (iLow(Symbol(), Period(), barIndex) < iLow(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthStart)))
                {
                    // Print("+BarIndex: ", barIndex, ", AR: ", iBarShift(Symbol(), Period(), mAccumulationAutomaticRally), ", UT Count: ", mAccumulationUpThrustCount, ", SOWS: ", iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthStart));
                    barIndex += (iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthStart) - barIndex + 1);
                    ResetAccumulation();

                    return;
                }

                if (mAccumulationSignOfStrengthEnd == EMPTY)
                {
                    mAccumulationSignOfStrengthEnd = iTime(Symbol(), Period(), barIndex);
                }
                else
                {
                    if (!mAccumulationHasLPS && iHigh(Symbol(), Period(), barIndex) > iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthEnd)))
                    {
                        // barIndex += (iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthStart) - barIndex + 1);
                        // ResetAccumulation();
                        mAccumulationSignOfStrengthEnd = iTime(Symbol(), Period(), barIndex);
                        // Draw(barIndex, clrBlue);
                    }
                    else if (!mAccumulationHasLPS && iHigh(Symbol(), Period(), barIndex) > iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationAutomaticRally)))
                    {
                        barIndex += (iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthStart) - barIndex + 1);
                        ResetAccumulation();
                    }
                    else if (!mAccumulationHasLPS && iHigh(Symbol(), Period(), barIndex) < iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationSignOfStrengthEnd)))
                    {
                        // Draw(barIndex, clrBlue);
                        mAccumulationHasLPS = true;
                    }
                    else if (mAccumulationHasLPS && iHigh(Symbol(), Period(), barIndex) > iHigh(Symbol(), Period(), iBarShift(Symbol(), Period(), mAccumulationAutomaticRally)))
                    {
                        Draw(barIndex, clrYellow);
                        ResetAccumulation();
                    }
                }
            }
        }
    }

    // if (mTrackBullishRange)
    // {
    // }

    // if (mTrackBearishRange)
    // {
    // }

    mHasSetup = false;
}

void CandleStickPatternTracker::ResetDistribution()
{
    mDistributionAutomaticRally = EMPTY;
    mDistributionUpThrustCount = 0;
    mDistributionSignOfWeaknessStart = EMPTY;
    mDistributionSignOfWeaknessEnd = EMPTY;
    mDistributionHasLPSY = false;
}

void CandleStickPatternTracker::ResetAccumulation()
{
    mAccumulationAutomaticRally = EMPTY;
    mAccumulationSignOfStrengthStart = EMPTY;
    mAccumulationSignOfStrengthEnd = EMPTY;
    mAccumulationUpThrustCount = 0;
    mAccumulationHasLPS = false;
}

bool CandleStickPatternTracker::HasSetup()
{
    Update();

    return mHasSetup;
}

void CandleStickPatternTracker::Draw(int barIndex, color clr)
{
    datetime barTime = iTime(Symbol(), Period(), barIndex);
    string name = "CandleStickPattern " + TimeToString(barTime);

    ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
    ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
}

void CandleStickPatternTracker::TrackBullishSignalCandle(bool track)
{
    if (mTrackBullishSignalCandle != track)
    {
        mBarsCalculated = 0;
        mTrackBullishSignalCandle = track;
    }
}

void CandleStickPatternTracker::TrackBearishSignalCandle(bool track)
{
    if (mTrackBearishSignalCandle != track)
    {
        mBarsCalculated = 0;
        mTrackBearishSignalCandle = track;
    }
}

void CandleStickPatternTracker::TrackBullishMalcom(bool track)
{
    if (mTrackBullishMalcom != track)
    {
        mBarsCalculated = 0;
        mTrackBullishMalcom = track;
    }
}

void CandleStickPatternTracker::TrackBearishMalcom(bool track)
{
    if (mTrackBearishMalcom != track)
    {
        mBarsCalculated = 0;
        mTrackBearishMalcom = track;
    }
}

void CandleStickPatternTracker::TrackBullishEngulfing(bool track)
{
    if (mTrackBullishEngulfing != track)
    {
        mBarsCalculated = 0;
        mTrackBullishEngulfing = track;
    }
}
void CandleStickPatternTracker::TrackBearishEngulfing(bool track)
{
    if (mTrackBearishEngulfing != track)
    {
        mBarsCalculated = 0;
        mTrackBearishEngulfing = track;
    }
}

void CandleStickPatternTracker::TrackBullishRun(bool track)
{
    if (mTrackBullishRun != track)
    {
        mBarsCalculated = 0;
        mTrackBullishRun = track;
    }
}

void CandleStickPatternTracker::TrackBearishRun(bool track)
{
    if (mTrackerBearishRun != track)
    {
        mBarsCalculated = 0;
        mTrackerBearishRun = track;
    }
}

void CandleStickPatternTracker::TrackHammerCandle(bool track)
{
    if (mTrackHammerCandle != track)
    {
        mBarsCalculated = 0;
        mTrackHammerCandle = track;
    }
}

void CandleStickPatternTracker::TrackShootingStarCandle(bool track)
{
    if (mTrackShootingStarCandle != track)
    {
        mBarsCalculated = 0;
        mTrackShootingStarCandle = track;
    }
}

void CandleStickPatternTracker::TrackEURejection(bool track)
{
    if (mTrackEURejection != track)
    {
        mBarsCalculated = 0;
        mTrackEURejection = track;
    }
}

void CandleStickPatternTracker::TrackDistribution(bool track)
{
    if (mTrackDistribution != track)
    {
        mBarsCalculated = 0;
        mTrackDistribution = track;
    }
}

void CandleStickPatternTracker::TrackAccumulation(bool track)
{
    if (mTrackAccumulation != track)
    {
        mBarsCalculated = 0;
        mTrackAccumulation = track;
    }
}

bool CandleStickPatternTracker::DistributionHasLPSY()
{
    Update();

    return mDistributionHasLPSY;
}

datetime CandleStickPatternTracker::DistributionSignOfWeaknessStart()
{
    Update();

    return mDistributionSignOfWeaknessStart;
}
