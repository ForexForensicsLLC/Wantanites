//+------------------------------------------------------------------+
//|                       SetupZoneIsValidForConfirmationTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class SetupHasZoneValidForConfirmationTracker
{
private:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mSetupMBNumber;

    void Update();
    void Calculate();

    void CheckRetappedDeepestHoldingSetupZone();
    void CheckPushedFurtherIntoDeepestHoldingSetupZone();

public:
    SetupHasZoneValidForConfirmationTracker();
    ~SetupHasZoneValidForConfirmationTracker();

    bool HasValidZoneForConfirmation(int mbNumber);
};

SetupHasZoneValidForConfirmationTracker::SetupHasZoneValidForConfirmationTracker(MBTracker *&setupMBT, MBTracker *&confirmationMBT)
{
}

SetupHasZoneValidForConfirmationTracker::~SetupHasZoneValidForConfirmationTracker()
{
}
