//+------------------------------------------------------------------+
//|                                              Errors.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class Errors
{
public:
    static int Errors::NO_ERROR;

    // =========================================================================
    // Terminal Errors
    // =========================================================================

    static bool IsTerminalError(int error);

    // 5000s Are for Indicator Errors
    static int MB_DOES_NOT_EXIST;
    static int NOT_EQUAL_SYMBOLS;
    static int NOT_EQUAL_TIMEFRAMES;
    static int BULLISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB;
    static int BEARISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB;

    // 5100s Are For Order Errors
    static int TICKET_IS_EMPTY;
    static int WRONG_ORDER_TYPE;
    static int STOPLOSS_PAST_ENTRY;
    static int ORDER_NOT_FOUND;
    static int MORE_THAN_ONE_UNMANAGED_TICKET;
    static int UNABLE_TO_FIND_PARTIALED_TICKET;

    // =========================================================================
    // Execution Errors
    // =========================================================================

    // 6000s Are For Indicator Errors
    static int Errors::SUBSEQUENT_MB_DOES_NOT_EXIST;
    static int Errors::MB_IS_NOT_MOST_RECENT;
    static int Errors::EQUAL_MB_TYPES;
    static int Errors::NOT_EQUAL_MB_TYPES;
    static int Errors::BULLISH_RETRACEMENT_IS_NOT_VALID;
    static int Errors::BEARISH_RETRACEMENT_IS_NOT_VALID;
    static int Errors::NO_ZONES;

    // 6100s Are For Order Errors
    static int Errors::NEW_STOPLOSS_EQUALS_OLD;
    static int Errors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    static int Errors::ORDER_IS_OPEN;
    static int Errors::ORDER_IS_CLOSED;
    static int Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
    static int Errors::WRONG_TYPE;
    static int Errors::EMPTY_TICKET;

    // 6200s Are for MQL Extension Errors
    static int Errors::COULD_NOT_RETRIEVE_LOW;
    static int Errors::COULD_NOT_RETRIEVE_HIGH;

    // 6300s Are for ScreenShot Errors
    static int Errors::SECOND_CHART_NOT_FOUND;

    // 6400s Are for Setup Errors
    static int Errors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND;
    static int Errors::ZONE_IS_NOT_HOLDING;
    static int Errors::MB_NOT_IN_ZONE;
    static int Errors::NOT_AFTER_POSSIBLE_ZONE_MITIGATION;
};
static int Errors::NO_ERROR = 0;
/*

   _____                   _             _   _____
  |_   _|__ _ __ _ __ ___ (_)_ __   __ _| | | ____|_ __ _ __ ___  _ __ ___
    | |/ _ \ '__| '_ ` _ \| | '_ \ / _` | | |  _| | '__| '__/ _ \| '__/ __|
    | |  __/ |  | | | | | | | | | | (_| | | | |___| |  | | | (_) | |  \__ \
    |_|\___|_|  |_| |_| |_|_|_| |_|\__,_|_| |_____|_|  |_|  \___/|_|  |___/


*/
static bool Errors::IsTerminalError(int error)
{
    return error > 1 && error < 6000;
}

// 5000s Are for Indicator Errors
static int Errors::MB_DOES_NOT_EXIST = 5000;
static int Errors::NOT_EQUAL_SYMBOLS = 5001;
static int Errors::NOT_EQUAL_TIMEFRAMES = 5002;
static int Errors::BULLISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB = 5003;
static int Errors::BEARISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB = 5004;

// 5100s Are For Order Errors
static int Errors::TICKET_IS_EMPTY = 5101;
static int Errors::WRONG_ORDER_TYPE = 5102;
static int Errors::STOPLOSS_PAST_ENTRY = 5103;
static int Errors::ORDER_NOT_FOUND = 5104;
static int Errors::MORE_THAN_ONE_UNMANAGED_TICKET = 5105;
static int Errors::UNABLE_TO_FIND_PARTIALED_TICKET = 5106;

/*

   _____                     _   _               _____
  | ____|_  _____  ___ _   _| |_(_) ___  _ __   | ____|_ __ _ __ ___  _ __ ___
  |  _| \ \/ / _ \/ __| | | | __| |/ _ \| '_ \  |  _| | '__| '__/ _ \| '__/ __|
  | |___ >  <  __/ (__| |_| | |_| | (_) | | | | | |___| |  | | | (_) | |  \__ \
  |_____/_/\_\___|\___|\__,_|\__|_|\___/|_| |_| |_____|_|  |_|  \___/|_|  |___/


*/
// 6000s Are For Indicator Errors
static int Errors::SUBSEQUENT_MB_DOES_NOT_EXIST = 6001;
static int Errors::MB_IS_NOT_MOST_RECENT = 6002;
static int Errors::EQUAL_MB_TYPES = 6003;
static int Errors::NOT_EQUAL_MB_TYPES = 6004;
static int Errors::BULLISH_RETRACEMENT_IS_NOT_VALID = 6005;
static int Errors::BEARISH_RETRACEMENT_IS_NOT_VALID = 6006;
static int Errors::NO_ZONES = 6007;

// 6100s Are For Order Errors
static int Errors::NEW_STOPLOSS_EQUALS_OLD = 6100;
static int Errors::ORDER_ENTRY_FURTHER_THEN_PRICE = 6101;
static int Errors::ORDER_IS_OPEN = 6102;
static int Errors::ORDER_IS_CLOSED = 6103;
static int Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER = 6104;
static int Errors::WRONG_TYPE = 6105;
static int Errors::EMPTY_TICKET = 6106;

// 6200s Are for MQL Extension Errors
static int Errors::COULD_NOT_RETRIEVE_LOW = 6200;
static int Errors::COULD_NOT_RETRIEVE_HIGH = 6201;

// 6300s Are for ScreenShot Errors
static int Errors::SECOND_CHART_NOT_FOUND = 6300;

// 6400s Are for Setup Errors
static int Errors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND = 6400;
static int Errors::ZONE_IS_NOT_HOLDING = 6401;
static int Errors::MB_NOT_IN_ZONE = 6402;
static int Errors::NOT_AFTER_POSSIBLE_ZONE_MITIGATION = 6403;
