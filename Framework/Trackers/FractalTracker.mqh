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

    ObjectList<Fractal> *mFractals;

    void Update();
    void Calculate(int barIndex);
    bool HasUpFractal(int barIndex);
    bool HasDownFractal(int barIndex);
    void CreateFractal(int barIndex, FractalType type);

public:
    FractalTracker(int period);
    ~FractalTracker();

    void GetFractalByIndex(int index, Fractal &fractal);

    bool IsUpFractal(int index);
    bool IsDownFractal(int index);

    bool HighestUpFractalOutOfPrevious(int nPrevious, Fractal &fractal);
    bool LowestDownFractalOutOfPrevious(int nPrevious, Fractal &fractal);

    void DrawFractals();
};

FractalTracker::FractalTracker(int period)
{
    mBarsCalculated = 0;
    mPeriod = period;

    mUpFractalCount = 0;
    mDownFractalCount = 0;

    mFractals = new ObjectList<Fractal>();

    Update();
}

FractalTracker::~FractalTracker()
{
    delete mFractals;
}

bool FractalTracker::HighestUpFractalOutOfPrevious(int nPrevious, Fractal &fractal)
{
    Update();

    if (nPrevious > mUpFractalCount)
    {
        return false;
    }

    int furthestIndex = -1;
    for (int i = mFractals.Size() - 1; i >= mFractals.Size() - 1 - nPrevious; i--)
    {
        if (mFractals[i].Type() == FractalType::Up)
        {
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
        }
    }

    if (furthestIndex > -1)
    {
        fractal = mFractals[furthestIndex];
        return true;
    }

    return false;
}

bool FractalTracker::LowestDownFractalOutOfPrevious(int nPrevious, Fractal &fractal)
{
    Update();

    if (nPrevious > mDownFractalCount)
    {
        return false;
    }

    int furthestIndex = -1;
    for (int i = mFractals.Size() - 1; i >= mFractals.Size() - 1 - nPrevious; i--)
    {
        if (mFractals[i].Type() == FractalType::Down)
        {
            if (furthestIndex == -1)
            {
                furthestIndex = i;
            }
            else
            {
                int currentFractalIndex = iBarShift(Symbol(), Period(), mFractals[i].CandleTime());
                int highestFractalIndex = iBarShift(Symbol(), Period(), mFractals[furthestIndex].CandleTime());

                if (iLow(Symbol(), Period(), currentFractalIndex) < iLow(Symbol(), Period(), highestFractalIndex))
                {
                    furthestIndex = i;
                }
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

void FractalTracker::Update()
{
    int currentBars = iBars(Symbol(), Period()) - mPeriod;
    int barIndex = currentBars - mBarsCalculated;

    if (barIndex <= 0)
    {
        return;
    }

    for (int i = barIndex; i > mPeriod; i--)
    {
        Calculate(i);
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
    mFractals.Add(fractal);
}

void FractalTracker::DrawFractals()
{
    Update();

    for (int i = mFractals.Size() - 1; i >= 0; i--)
    {
        mFractals[i].Draw();
    }
}