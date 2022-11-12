//+------------------------------------------------------------------+
//|                                                   EAErrorHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class EAErrorHelper
{
public:
    template <typename TEA>
    static void RecordFailMBRetrievalError(TEA &ea, int error, MBTracker *&mbt, int mbNumber);
};

template <typename TEA>
static void EAErrorHelper::RecordFailMBRetrievalError(TEA &ea, int error, MBTracker *&mbt, int mbNumber)
{
    string additionalInfo = "Total MBs: " + mbt.MBsCreated() + " MB Number: " + mbNumber + ". You're probably not resetting the MB Number.";
    ea.RecordError(error, additionalInfo);
}