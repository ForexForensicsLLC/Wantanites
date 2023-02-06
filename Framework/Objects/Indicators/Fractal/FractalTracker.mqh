//+------------------------------------------------------------------+
//|                                               FractalTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Fractal.mqh>
#include <SummitCapital\Framework\Objects\ObjectList.mqh>
#include <SummitCapital\Framework\Helpers\MQLHelper.mqh>

class FractalTracker
{
private:
    int mBarsCalculated;
    int mPeriod;

    int mUpFractalCount;
    int mDownFractalCount;

    Fractal *mFractals[];

    void Update();
    void Calculate(int barIndex);
    bool HasUpFractal(int barIndex);
    bool HasDownFractal(int barIndex);
    void CreateFractal(int barIndex, FractalType type);

public:
    FractalTracker(int period);
    ~FractalTracker();

    // --BEWARE-- this will be off by one in respect to the current actual bar index i.e [0] will be for the 1st previous bar
    Fractal *operator[](int index);

    int UpFractalCount() { return mUpFractalCount; }
    int DownFractalCount() { return mDownFractalCount; }

    bool IsUpFractal(int index);
    bool IsDownFractal(int index);

    bool HighestUpFractalOutOfPrevious(int nPrevious, Fractal *&fractal);
    bool LowestDownFractalOutOfPrevious(int nPrevious, Fractal *&fractal);

    bool FractalIsHighestOutOfPrevious(int fractalIndex, int nPrevious, Fractal *&fractal);
    bool FractalIsLowestOutOfPrevious(int fractalIndex, int nPrevious, Fractal *&fractal);

    bool GetMostRecentFractal(FractalType type, Fractal *&fractal);
};

FractalTracker::FractalTracker(int period)
{
    mBarsCalculated = 0;
    mPeriod = period;

    mUpFractalCount = 0;
    mDownFractalCount = 0;

    ArrayResize(mFractals, 0);

    Update();
}

FractalTracker::~FractalTracker()
{
    for (int i = 0; i < ArraySize(mFractals); i++)
    {
        delete mFractals[i];
    }
}

Fractal *FractalTracker::operator[](int index)
{
    Update();
    return mFractals[index];
}

bool FractalTracker::HighestUpFractalOutOfPrevious(int nPrevious, Fractal *&fractal)
{
    Update();

    if (nPrevious > mUpFractalCount)
    {
        return false;
    }

    int furthestIndex = -1;
    int count = 0;
    for (int i = 0; i < ArraySize(mFractals); i++)
    {
        if (mFractals[i].Type() == FractalType::Up)
        {
            count += 1;

            if (furthestIndex == -1)
            {
                furthestIndex = i;
            }
            else
            {
                int currentFractalIndex = iBarShift(Symbol(), Period(), mFractals[i].CandleTime());
                int highestFractalIndex = iBarShift(Symbol(), Period(), mFractals[furthestIndex].CandleTime());

                if (iHigh(Symbol(), Period(), currentFractalIndex) > iHigh(Symbol(), Period(), highestFractalIndex))
                {
                    furthestIndex = i;
                }
            }

            if (count == nPrevious)
            {
                break;
            }
        }
    }

    if (furthestIndex > -1)
    {
        fractal = mFractals[furthestIndex];
        return true;
    }

    return false;
}

bool FractalTracker::LowestDownFractalOutOfPrevious(int nPrevious, Fractal *&fractal)
{
    Update();

    if (nPrevious > mDownFractalCount)
    {
        return false;
    }

    int furthestIndex = -1;
    int count = 0;
    for (int i = 0; i < ArraySize(mFractals); i++)
    {
        if (mFractals[i].Type() == FractalType::Down)
        {
            count += 1;

            if (furthestIndex == -1)
            {
                furthestIndex = i;
            }
            else
            {
                int currentFractalIndex = iBarShift(Symbol(), Period(), mFractals[i].CandleTime());
                int lowestFractalIndex = iBarShift(Symbol(), Period(), mFractals[furthestIndex].CandleTime());

                if (iLow(Symbol(), Period(), currentFractalIndex) < iLow(Symbol(), Period(), lowestFractalIndex))
                {
                    furthestIndex = i;
                }
            }

            if (count == nPrevious)
            {
                break;
            }
        }
    }

    if (furthestIndex > -1)
    {
        fractal = mFractals[furthestIndex];
        return true;
    }

    return false;
}

bool FractalTracker::FractalIsHighestOutOfPrevious(int fractalIndex, int nPrevious, Fractal *&fractal)
{
    if (!HighestUpFractalOutOfPrevious(nPrevious, fractal))
    {
        return false;
    }

    return fractal.CandleTime() == mFractals[fractalIndex].CandleTime();
}
bool FractalTracker::FractalIsLowestOutOfPrevious(int fractalIndex, int nPrevious, Fractal *&fractal)
{
    if (!LowestDownFractalOutOfPrevious(nPrevious, fractal))
    {
        return false;
    }

    return fractal.CandleTime() == mFractals[fractalIndex].CandleTime();
}

bool FractalTracker::GetMostRecentFractal(FractalType type, Fractal *&fractal)
{
    for (int i = 0; i < ArraySize(mFractals); i++)
    {
        if (mFractals[i].Type() == type)
        {
            fractal = mFractals[i];
            return true;
        }
    }

    return false;
}

void FractalTracker::Update()
{
    int currentBars = iBars(Symbol(), Period()) - mPeriod;
    int barsToCalculate = currentBars - mBarsCalculated;

    for (int i = barsToCalculate; i > 0; i--)
    {
        Calculate(i + mPeriod);
    }

    mBarsCalculated = currentBars;
}

void FractalTracker::Calculate(int barIndex)
{
    if (HasUpFractal(barIndex))
    {
        CreateFractal(barIndex, FractalType::Up);
        mUpFractalCount += 1;
    }
    else if (HasDownFractal(barIndex))
    {
        CreateFractal(barIndex, FractalType::Down);
        mDownFractalCount += 1;
    }
}

bool FractalTracker::HasUpFractal(int barIndex)
{
    int highestBefore = 0.0;
    if (!MQLHelper::GetHighestIndexBetween(Symbol(), Period(), barIndex + mPeriod, barIndex, true, highestBefore))
    {
        return false;
    }

    if (highestBefore != barIndex)
    {
        return false;
    }

    int highestAfter = 0.0;
    if (!MQLHelper::GetHighestIndexBetween(Symbol(), Period(), barIndex, barIndex - mPeriod, true, highestAfter))
    {
        return false;
    }

    if (highestAfter != barIndex)
    {
        return false;
    }

    return true;
}

bool FractalTracker::HasDownFractal(int barIndex)
{
    int lowestBefore = 0.0;
    if (!MQLHelper::GetLowestIndexBetween(Symbol(), Period(), barIndex + mPeriod, barIndex, true, lowestBefore))
    {
        return false;
    }

    if (lowestBefore != barIndex)
    {
        return false;
    }

    int lowestAfter = 0.0;
    if (!MQLHelper::GetLowestIndexBetween(Symbol(), Period(), barIndex, barIndex - mPeriod, true, lowestAfter))
    {
        return false;
    }

    if (lowestAfter != barIndex)
    {
        return false;
    }

    return true;
}

void FractalTracker::CreateFractal(int barIndex, FractalType type)
{
    Fractal *fractal = new Fractal(barIndex, type);
    fractal.Draw();

    ArrayResize(mFractals, ArraySize(mFractals) + 1);
    ArrayCopy(mFractals, mFractals, 1, 0);
    mFractals[0] = fractal;
}