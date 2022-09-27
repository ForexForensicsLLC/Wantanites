//+------------------------------------------------------------------+
//|                                        MBWyckoffTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class MBWyckoffTracker
{
private:
    MBTracker *mMBT;

    int mSetupType;
    int mMBsCalculated;

    int mFirstConsecutiveMB;
    int mFirstMBBreak;
    int mFirstRetracementMB;
    int mSecondMBBreak;
    int mSetupCompletionMB;

    void
    Update();
    void Reset();

    void CheckInvalidateSetup();
    void CheckSetup(int mbNumber);

public:
    MBWyckoffTracker(int setupType, MBTracker *&mbt);
    ~MBWyckoffTracker();

    bool HasSetup();
};

MBWyckoffTracker::MBWyckoffTracker(int setupType, MBTracker *&mbt)
{
    mMBT = mbt;

    mSetupType = setupType;
    mMBsCalculated = 0;

    mFirstConsecutiveMB = EMPTY;
    mFirstMBBreak = EMPTY;
    mFirstRetracementMB = EMPTY;
    mSecondMBBreak = EMPTY;
    mSetupCompletionMB = EMPTY;

    Update();
}

MBWyckoffTracker::~MBWyckoffTracker()
{
    ObjectsDeleteAll(ChartID(), "Wyckoff");
}

void MBWyckoffTracker::Update()
{
    CheckInvalidateSetup();

    while (mMBsCalculated < mMBT.MBsCreated())
    {
        CheckInvalidateSetup();
        CheckSetup(mMBsCalculated);

        mMBsCalculated += 1;
    }
}

void MBWyckoffTracker::CheckInvalidateSetup()
{
}

void MBWyckoffTracker::Reset()
{
    mFirstConsecutiveMB = EMPTY;
    mFirstMBBreak = EMPTY;
    mFirstRetracementMB = EMPTY;
    mSecondMBBreak = EMPTY;
    mSetupCompletionMB = EMPTY;
}

void MBWyckoffTracker::CheckSetup(int mbNumber)
{
    if (mSetupCompletionMB == EMPTY)
    {
        MBState *currentMB;
        if (!mMBT.GetMB(mbNumber, currentMB))
        {
            Reset();
            return;
        }

        if (mFirstMBBreak == EMPTY)
        {
            if (currentMB.Type() != mSetupType)
            {
                return;
            }

            MBState *previousMBState;
            if (!mMBT.GetPreviousMB(mbNumber, previousMBState))
            {
                return;
            }

            int consecutiveMBs = mMBT.NumberOfConsecutiveMBsBeforeMB(mbNumber);
            if (consecutiveMBs < 3 || previousMBState.Type() == mSetupType)
            {
                return;
            }

            mFirstMBBreak = mbNumber;
            mFirstConsecutiveMB = mbNumber - consecutiveMBs;

            // MBState *firstBreak;
            // mMBT.GetMB(mFirstMBBreak, firstBreak);

            // datetime barTime = iTime(Symbol(), Period(), firstBreak.EndIndex());
            // string name = "Wyckoff" + TimeToString(barTime);
            // color clr = firstBreak.Type() == OP_BUY ? clrLimeGreen : clrRed;

            // ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
            // ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrPurple);
        }
        else
        {
            // MBState *firstConsecutiveMB;
            // if (!mMBT.GetMB(mFirstConsecutiveMB, firstConsecutiveMB))
            // {
            //     Reset();
            //     return;
            // }

            // if (firstConsecutiveMB.StartIsBrokenFromBarIndex(currentMB.EndIndex()))
            // {
            //     Reset();
            //     return;
            // }

            if (mFirstRetracementMB == EMPTY)
            {
                if (mMBT.MBIsOpposite(mbNumber))
                {
                    mFirstRetracementMB = mbNumber;

                    // MBState *firstRetracement;
                    // mMBT.GetMB(mFirstRetracementMB, firstRetracement);

                    // datetime barTime = iTime(Symbol(), Period(), firstRetracement.EndIndex());
                    // string name = "Wyckoff" + TimeToString(barTime);

                    // ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
                    // ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrOrange);

                    // Print("MB Number: " + mFirstRetracementMB + ", Time: " + barTime);
                }
            }
            else
            {
                if (mSecondMBBreak == EMPTY)
                {
                    if (mMBT.MBIsOpposite(mbNumber))
                    {
                        mSecondMBBreak = mbNumber;

                        // MBState *secondBreak;
                        // mMBT.GetMB(mSecondMBBreak, secondBreak);

                        // datetime barTime = iTime(Symbol(), Period(), secondBreak.EndIndex());
                        // string name = "Wyckoff" + TimeToString(barTime);
                        // color clr = secondBreak.Type() == OP_BUY ? clrLimeGreen : clrRed;

                        // ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
                        // ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrYellow);

                        // go back one in case our second break also broke the first retracement mb
                        mMBsCalculated -= 1;
                    }
                }
                else
                {
                    MBState *secondMBBreak;
                    if (!mMBT.GetMB(mSecondMBBreak, secondMBBreak))
                    {
                        Reset();
                        return;
                    }

                    if (secondMBBreak.StartIsBrokenFromBarIndex(currentMB.EndIndex()))
                    {
                        mMBsCalculated -= (mbNumber - mFirstMBBreak - 1);
                        Reset();
                        return;
                    }

                    MBState *firstRetracementMB;
                    if (!mMBT.GetMB(mFirstRetracementMB, firstRetracementMB))
                    {
                        Reset();
                        return;
                    }

                    if (firstRetracementMB.StartIsBrokenFromBarIndex(currentMB.EndIndex()))
                    {
                        mSetupCompletionMB = mbNumber;

                        MBState *setupCompletionMB;
                        mMBT.GetMB(mSetupCompletionMB, setupCompletionMB);

                        datetime barTime = iTime(Symbol(), Period(), setupCompletionMB.EndIndex());
                        string name = "Wyckoff" + TimeToString(barTime);
                        color clr = mSetupType == OP_BUY ? clrLimeGreen : clrRed;

                        ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
                        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
                    }
                }
            }
        }
    }
    else
    {
        if (mbNumber != mSetupCompletionMB)
        {
            Reset();
        }
    }
}

bool MBWyckoffTracker::HasSetup()
{
    Update();
    return mSetupCompletionMB != EMPTY;
}
