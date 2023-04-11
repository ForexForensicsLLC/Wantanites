//+------------------------------------------------------------------+
//|                                                    CandlePart.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

enum CandlePart
{
    Body,
    Wick
};

enum ZonePartInMB
{
    Whole,
    Exit,
    None
};