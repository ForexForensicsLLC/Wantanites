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

    // 5100s Are For Order Errors
    static int TICKET_IS_EMPTY;
    static int WRONG_ORDER_TYPE;
    static int STOPLOSS_ABOVE_ENTRY;
    static int ORDER_IS_CLOSED;
    static int ORDER_IS_OPEN;
    static int ORDER_NOT_FOUND;
};

static bool TerminalErrors::IsTerminalError(int error)
{
    return error != ERR_NO_ERROR && error < 6000;
}

// 5000s Are for Indicator Errors
static int TerminalErrors::MB_DOES_NOT_EXIST = 5000;
static int TerminalErrors::NOT_EQUAL_SYMBOLS = 5001;
static int TerminalErrors::NOT_EQUAL_TIMEFRAMES = 5002;

// 5100s Are For Order Errors
static int TerminalErrors::TICKET_IS_EMPTY = 5101;
static int TerminalErrors::WRONG_ORDER_TYPE = 5102;
static int TerminalErrors::STOPLOSS_ABOVE_ENTRY = 5103;
static int TerminalErrors::ORDER_IS_CLOSED = 5104;
static int TerminalErrors::ORDER_IS_OPEN = 5105;
static int TerminalErrors::ORDER_NOT_FOUND = 5106;