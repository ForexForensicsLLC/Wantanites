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
    static int ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID;
    static int ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID;
    static int ExecutionErrors::NO_ZONES;

    // 6100s Are For Order Errors
    static int ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
    static int ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    static int ExecutionErrors::ORDER_IS_OPEN;
    static int ExecutionErrors::ORDER_IS_CLOSED;

    // 6200s Are for MQL Extension Errors
    static int ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
    static int ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;

    // 6300s Are for ScreenShot Errors
    static int ExecutionErrors::SECOND_CHART_NOT_FOUND;

    // 6400s Are for Setup Errors
    static int ExecutionErrors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND;
    static int ExecutionErrors::ZONE_IS_NOT_HOLDING;
    static int ExecutionErrors::MB_NOT_IN_ZONE;
    static int ExecutionErrors::NOT_AFTER_POSSIBLE_ZONE_MITIGATION;
};

// 6000s Are For Indicator Errors
static int ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST = 6001;
static int ExecutionErrors::MB_IS_NOT_MOST_RECENT = 6002;
static int ExecutionErrors::EQUAL_MB_TYPES = 6003;
static int ExecutionErrors::NOT_EQUAL_MB_TYPES = 6004;
static int ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID = 6005;
static int ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID = 6006;
static int ExecutionErrors::NO_ZONES = 6007;

// 6100s Are For Order Errors
static int ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD = 6100;
static int ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE = 6101;
static int ExecutionErrors::ORDER_IS_OPEN = 6102;
static int ExecutionErrors::ORDER_IS_CLOSED = 6103;

// 6200s Are for MQL Extension Errors
static int ExecutionErrors::COULD_NOT_RETRIEVE_LOW = 6200;
static int ExecutionErrors::COULD_NOT_RETRIEVE_HIGH = 6201;

// 6300s Are for ScreenShot Errors
static int ExecutionErrors::SECOND_CHART_NOT_FOUND = 6300;

// 6400s Are for Setup Errors
static int ExecutionErrors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND = 6400;
static int ExecutionErrors::ZONE_IS_NOT_HOLDING = 6401;
static int ExecutionErrors::MB_NOT_IN_ZONE = 6402;
static int ExecutionErrors::NOT_AFTER_POSSIBLE_ZONE_MITIGATION = 6403;
