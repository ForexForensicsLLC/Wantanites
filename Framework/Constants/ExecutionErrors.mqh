//+------------------------------------------------------------------+
//|                                              ExecutionErrors.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class ExecutionErrors
{
public:
    // 6000s Are For Indicator Errors
    static int ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
    static int ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    static int ExecutionErrors::EQUAL_MB_TYPES;
    static int ExecutionErrors::NOT_EQUAL_MB_TYPES;
    static int ExecutionErrors::EMPTY_BULLISH_RETRACEMENT;
    static int ExecutionErrors::EMPTY_BEARISH_RETRACEMENT;

    // 6100s Are For Order Errors
    static int ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
};

// 6000s Are For Indicator Errors
static int ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST = 6001;
static int ExecutionErrors::MB_IS_NOT_MOST_RECENT = 6002;
static int ExecutionErrors::EQUAL_MB_TYPES = 6003;
static int ExecutionErrors::NOT_EQUAL_MB_TYPES = 6004;
static int ExecutionErrors::EMPTY_BULLISH_RETRACEMENT = 6007;
static int ExecutionErrors::EMPTY_BEARISH_RETRACEMENT = 6008;

// 6100s Are For Order Errors
static int ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD = 6104;
