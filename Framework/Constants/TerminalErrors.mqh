//+------------------------------------------------------------------+
//|                                               TerminalErrors.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class TerminalErrors
{
public:
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
};

static bool TerminalErrors::IsTerminalError(int error)
{
    return error > 1 && error < 6000;
}

// 5000s Are for Indicator Errors
static int TerminalErrors::MB_DOES_NOT_EXIST = 5000;
static int TerminalErrors::NOT_EQUAL_SYMBOLS = 5001;
static int TerminalErrors::NOT_EQUAL_TIMEFRAMES = 5002;
static int TerminalErrors::BULLISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB = 5003;
static int TerminalErrors::BEARISH_RETRACEMENT_INDEX_FURTHER_THAN_PREVIOUS_MB = 5004;

// 5100s Are For Order Errors
static int TerminalErrors::TICKET_IS_EMPTY = 5101;
static int TerminalErrors::WRONG_ORDER_TYPE = 5102;
static int TerminalErrors::STOPLOSS_PAST_ENTRY = 5103;
static int TerminalErrors::ORDER_NOT_FOUND = 5104;
static int TerminalErrors::MORE_THAN_ONE_UNMANAGED_TICKET = 5105;
static int TerminalErrors::UNABLE_TO_FIND_PARTIALED_TICKET = 5106;