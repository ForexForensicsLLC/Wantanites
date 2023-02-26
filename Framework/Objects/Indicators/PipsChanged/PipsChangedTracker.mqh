//+------------------------------------------------------------------+
//|                                                   PipsChangedTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataStructures\ObjectList.mqh>
#include <WantaCapital\Framework\Objects\Indicators\PipsChanged\PipsChanged.mqh>

class PipsChangedTracker
{
private:
    int mTimeFrame;
    int mMAPeriod;

    ObjectList<PipsChanged> *mPipsChanged;

public:
    PipsChangedTracker(int timeFrame, int smaPeriod);
    ~PipsChangedTracker();

    void Update();
    void TrackSymbol(string symbol, color plotClr);
};

PipsChangedTracker::PipsChangedTracker(int timeFrame, int maPeriod)
{
    // used to open a sub window. File needs to be in the ~/MQL4/Indicators/ directory
    double subWindow = iCustom(Symbol(), timeFrame, "SubWindow", 0, 0);

    mTimeFrame = timeFrame;
    mMAPeriod = maPeriod;

    mPipsChanged = new ObjectList<PipsChanged>();
}

PipsChangedTracker::~PipsChangedTracker()
{
    delete mPipsChanged;
}

void PipsChangedTracker::TrackSymbol(string symbol, color plotClr)
{
    PipsChanged *pc = new PipsChanged(symbol, mTimeFrame, mMAPeriod, plotClr);
    mPipsChanged.Add(pc);
}

void PipsChangedTracker::Update()
{
    for (int i = 0; i < mPipsChanged.Size(); i++)
    {
        mPipsChanged[i].Update();
    }
}
