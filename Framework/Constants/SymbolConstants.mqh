//+------------------------------------------------------------------+
//|                                                      SymbolConstants.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

/// @brief All values are during NY Session
class SymbolConstants
{
public:
    static double NasSpreadPips;
    static double NasSlippagePips;

    static double SPXSpreadPips;
    static double SPXSlippagePips;

    static double DowSpreadPips;
    static double DowSlippagePips;

    static double GoldSpreadPips;
    static double GoldSlippagePips;
};

double SymbolConstants::NasSpreadPips = 10;
double SymbolConstants::NasSlippagePips = 50;

double SymbolConstants::SPXSpreadPips = 3;
double SymbolConstants::SPXSlippagePips = 20;

double SymbolConstants::DowSpreadPips = 18;
double SymbolConstants::DowSlippagePips = 50;

double SymbolConstants::GoldSpreadPips = 3;
double SymbolConstants::GoldSlippagePips = 3;
