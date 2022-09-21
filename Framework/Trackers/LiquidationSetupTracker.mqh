//+------------------------------------------------------------------+
//|                                      LiquidationSetupTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class LiquidationSetupTracker
{
private:
    MBTracker *mMBT;

    int mSetupType;
    int mMBsCalculated;

    int mFirstMBNumberInSetup;
    int mSecondMBNumberInSetup;
    int mLiquidationMBNumberInSetup;

    void Update();
    void Reset();

    void CheckInvalidateSetup();
    void CheckSetup(int mbNumber);

public:
    LiquidationSetupTracker(int setupType, MBTracker *&mbt);
    ~LiquidationSetupTracker();

    bool HasSetup(int &firstMBNumberInSetup, int &secondMBNumberInSetup, int &liquidationMBNumberInSetup);
};

LiquidationSetupTracker::LiquidationSetupTracker(int setupType, MBTracker *&mbt)
{
    mMBT = mbt;

    mSetupType = setupType;
    mMBsCalculated = 0;

    mFirstMBNumberInSetup = EMPTY;
    mSecondMBNumberInSetup = EMPTY;
    mLiquidationMBNumberInSetup = EMPTY;
}

LiquidationSetupTracker::~LiquidationSetupTracker()
{
    // nothing to clean up
}

void LiquidationSetupTracker::Update()
{
    // add a check here in case we are fully updated but the first mb in the range is broken (doens't have to be a new mb)
    CheckInvalidateSetup();

    while (mMBsCalculated < mMBT.MBsCreated())
    {
        CheckInvalidateSetup();
        CheckSetup(mMBsCalculated);

        mMBsCalculated += 1;
    }
}

void LiquidationSetupTracker::Reset()
{
    mFirstMBNumberInSetup = EMPTY;
    mSecondMBNumberInSetup = EMPTY;
    mLiquidationMBNumberInSetup = EMPTY;
}

void LiquidationSetupTracker::CheckInvalidateSetup()
{
    if (mFirstMBNumberInSetup != EMPTY)
    {
        MBState *tempMBState;
        if (!mMBT.GetMB(mFirstMBNumberInSetup, tempMBState))
        {
            Reset();
            return;
        }

        if (tempMBState.StartIsBroken())
        {
            Reset();
            return;
        }
    }

    if (mLiquidationMBNumberInSetup != EMPTY)
    {
        MBState *tempMBState;
        if (!mMBT.GetMB(mLiquidationMBNumberInSetup, tempMBState))
        {
            Reset();
            return;
        }

        if (tempMBState.StartIsBroken())
        {
            // subtract 2 here since we could have started a new setup during the previous one
            mMBsCalculated -= 2;
            Reset();

            return;
        }
    }
}

void LiquidationSetupTracker::CheckSetup(int mbNumber)
{
    if (mFirstMBNumberInSetup == EMPTY)
    {
        MBState *firstMBState;
        if (!mMBT.GetMB(mbNumber, firstMBState))
        {
            return;
        }

        if (firstMBState.Type() != mSetupType || firstMBState.StartIsBroken())
        {
            Reset();
            return;
        }

        mFirstMBNumberInSetup = firstMBState.Number();
    }
    else if (mSecondMBNumberInSetup == EMPTY)
    {
        if (mbNumber != (mFirstMBNumberInSetup + 1))
        {
            // subtract 2 since we got seperated. Recalc the setup
            mMBsCalculated -= 2;
            Reset();

            return;
        }

        MBState *secondMBState;
        if (!mMBT.GetMB(mbNumber, secondMBState))
        {
            // reset here since this mbnumber should always exist since we should only
            // reach this point if we have a new mb after already setting the first one
            Reset();
            return;
        }

        if (secondMBState.Type() != mSetupType)
        {
            // don't need to subtract here since we can't be in a new setup
            Reset();
            return;
        }

        mSecondMBNumberInSetup = secondMBState.Number();
    }
    else if (mLiquidationMBNumberInSetup == EMPTY)
    {
        if (mbNumber != (mSecondMBNumberInSetup + 1))
        {
            // subtract 3 since we got seerated. Recalc the setup
            mMBsCalculated -= 3;
            Reset();

            return;
        }

        MBState *liquidationMBState;
        if (!mMBT.GetMB(mbNumber, liquidationMBState))
        {
            // reset here since this mbnumber should always exist since we should only
            // reach this point if we have a new mb after already setting the first two
            Reset();
            return;
        }

        if (liquidationMBState.Type() == mSetupType)
        {
            // subtract 2 since the previous 2 MBs are also the start of a new potential setup
            mMBsCalculated -= 2;
            Reset();

            return;
        }

        mLiquidationMBNumberInSetup = liquidationMBState.Number();
    }
}

bool LiquidationSetupTracker::HasSetup(int &firstMBNumberInSetup, int &secondMBNumberInSetup, int &liquidationMBNumberInSetup)
{
    Update();

    if (mFirstMBNumberInSetup != EMPTY && mSecondMBNumberInSetup != EMPTY && mLiquidationMBNumberInSetup != EMPTY)
    {
        firstMBNumberInSetup = mFirstMBNumberInSetup;
        secondMBNumberInSetup = mSecondMBNumberInSetup;
        liquidationMBNumberInSetup = mLiquidationMBNumberInSetup;

        return true;
    }

    return false;
}