//+------------------------------------------------------------------+
//|                                                      IRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property strict

interface ICSVRecord
{
    void Write(int fileHandle);
    void Reset();
};