//+------------------------------------------------------------------+
//|                                                       Errors.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#define out

class Errors
{
public:
   // 300s are for Indicator Errors
   static int ERR_MB_DOES_NOT_EXIST;
   static int ERR_SUBSEQUENT_MB_DOES_NOT_EXIST;
   static int ERR_MB_IS_NOT_MOST_RECENT;
   static int ERR_EQUAL_MB_TYPES;
   static int ERR_NOT_EQUAL_MB_TYPES;
   static int ERR_NOT_EQUAL_SYMBOLS;
   static int ERR_NOT_EQUAL_TIMEFRAMES;
   static int ERR_EMPTY_BULLISH_RETRACEMENT;
   static int ERR_EMPTY_BEARISH_RETRACEMENT;

   // 400s are for order errors
   static int ERR_WRONG_ORDER_TYPE;
   static int ERR_STOPLOSS_ABOVE_ENTRY;
   static int ERR_NEW_STOPLOSS_EQUALS_OLD;
   static int ERR_UNABLE_TO_DELETE_PENDING_ORDER;
};
// 300s are for Indicator Errors
static int Errors::ERR_MB_DOES_NOT_EXIST = 300;
static int Errors::ERR_SUBSEQUENT_MB_DOES_NOT_EXIST = 301;
static int Errors::ERR_MB_IS_NOT_MOST_RECENT = 302;
static int Errors::ERR_EQUAL_MB_TYPES = 303;
static int Errors::ERR_NOT_EQUAL_MB_TYPES = 304;
static int Errors::ERR_NOT_EQUAL_SYMBOLS = 305;
static int Errors::ERR_NOT_EQUAL_TIMEFRAMES = 306;
static int Errors::ERR_EMPTY_BULLISH_RETRACEMENT = 307;
static int Errors::ERR_EMPTY_BEARISH_RETRACEMENT = 308;

// 400s are for order errors
static int Errors::ERR_WRONG_ORDER_TYPE = 402;
static int Errors::ERR_STOPLOSS_ABOVE_ENTRY = 403;
static int Errors::ERR_NEW_STOPLOSS_EQUALS_OLD = 404;
static int Errors::ERR_UNABLE_TO_DELETE_PENDING_ORDER = 405;