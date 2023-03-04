//+------------------------------------------------------------------+
//|                                                 DojiRecorder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\ScreenShotHelper.mqh>
#include <Wantanites\Framework\Helpers\MQLHelper.mqh>

struct Doji
{
    datetime CandleTime;
    int Type;
};

// -- MBTracker Inputs
input int MBsToTrack = 10000;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int BarsCalculated = 0;
bool CurrentlyHasDoji = false;
datetime TempDojiTime = 0;
Doji Dojis[];

MBTracker *SetupMBT;

string DojiDir = "DojiRecorder/SimpleDoji/";

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    ArrayResize(Dojis, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    for (int i = ArraySize(Dojis) - 1; i >= 0; i--)
    {
    }
}

void OnTick()
{
    SetupMBT.DrawNMostRecentMBs(-1);
    SetupMBT.DrawZonesForNMostRecentMBs(-1);

    int currentBars = iBars(Symbol(), Period());

    if (!CurrentHasDoji && currentBars > BarsCalculated)
    {
        MBState *tempMBState;
        if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        ZoneState *tempZoneState;
        if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
        {
            return;
        }

        bool hasDoji = (tempZoneState.Type() == OP_BUY && SetupHelper::HammerCandleStickPattern(Symbol(), Period(), 1)) ||
                       (tempZoneState.Type() == OP_SELL && SetupHelper::ShootingStarCandleStickPattern(Symbol(), Period(), 1));

        if (hasDoji)
        {
            CurrentlyHasDoji = true;
            TempDojiTime = iTIme(Symbol(), Period(), 1);
        }

        BarsCalculated = currentBars;
    }
    else if (CurrentlyHasDoji)
    {
        if (InvalidateDoji())
        {
            CurrentlyHasDoji = false;
        }
        else if (HasEntry())
        {
            Doji doji =
            {
                iTime()
            }
        }
    }
}

void CheckEntry()
{
}

void CheckInvalidate(int)
{
}
