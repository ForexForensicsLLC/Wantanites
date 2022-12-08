//+------------------------------------------------------------------+
//|                                                   EAErrorHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\ExecutionErrors.mqh>
#include <SummitCapital\Framework\Constants\TerminalErrors.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class EAErrorHelper
{
public:
    template <typename TEA>
    static void RecordFailedMBRetrievalError(TEA &ea, MBTracker *&mbt, int mbNumber, int error);
};

template <typename TEA>
static void EAErrorHelper::RecordFailedMBRetrievalError(TEA &ea, MBTracker *&mbt, int mbNumber, int error = -1)
{
    if (error == -1)
    {
        error = TerminalErrors::MB_DOES_NOT_EXIST;
    }

    string additionalInfo = "Total MBs: " + mbt.MBsCreated() + " MB Number: " + mbNumber + ". You're probably not resetting the MB Number.";
    ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST, additionalInfo);
}