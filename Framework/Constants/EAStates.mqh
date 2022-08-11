//+------------------------------------------------------------------+
//|                                                  ControlFlow.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class EAStates
{
public:
    // 8000s Are For General States
    static int EAStates::CHECKING_IF_ALLOWED_TO_TRADE;
    static int EAStates::FILLING_STRATEGY_MAGIC_NUMBERS;
    static int EAStates::RESETING;
    static int EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    // 8100s Are For Order Related States
    static int EAStates::CHECKING_IF_PENDING_ORDER;
    static int EAStates::CANCELING_PENDING_ORDER;
    static int EAStates::CHECKING_TO_EDIT_STOP_LOSS;
    static int EAStates::CHECKING_TO_TRAIL_STOP_LOSS;
    static int EAStates::COUNTING_OTHER_EA_ORDERS;
    static int EAStates::PLACING_ORDER;
    static int EAStates::RECORDING_PRE_ORDER_OPEN_DATA;
    static int EAStates::RECORDING_POST_ORDER_OPEN_DATA;
    static int EAStates::RECORDING_POST_ORDER_CLOSE_DATA;

    // 8200s Are For Setup Related States
    static int EAStates::CHECKING_FOR_SETUP;
    static int EAStates::CHECKING_FOR_INVALID_SETUP;
    static int EAStates::INVALIDATING_SETUP;
    static int EAStates::CHECKING_IF_BROKE_RANGE_START;
    static int EAStates::CHECKING_FOR_SAME_TYPE_SUBSEQUENT_MB;
    static int EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;
    static int EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;
    static int EAStates::GETTING_NTH_MOST_RECENT_MB;

    // 8300s Are For Confirmation Related States
    static int EAStates::CHECKING_FOR_CONFIRMATION;
    static int EAStates::CHECKING_FOR_MOST_RECENT_MB_PLUS_HOLDING_ZONE;
};

// 8000s Are For General States
static int EAStates::CHECKING_IF_ALLOWED_TO_TRADE = 8000;
static int EAStates::FILLING_STRATEGY_MAGIC_NUMBERS = 8001;
static int EAStates::RESETING = 8002;
static int EAStates::ATTEMPTING_TO_MANAGE_ORDER = 8003;

// 8100s Are For Order Related States
static int EAStates::CHECKING_IF_PENDING_ORDER = 8100;
static int EAStates::CANCELING_PENDING_ORDER = 8101;
static int EAStates::CHECKING_TO_EDIT_STOP_LOSS = 8102;
static int EAStates::CHECKING_TO_TRAIL_STOP_LOSS = 8103;
static int EAStates::COUNTING_OTHER_EA_ORDERS = 8103;
static int EAStates::PLACING_ORDER = 8104;
static int EAStates::RECORDING_PRE_ORDER_OPEN_DATA = 8105;
static int EAStates::RECORDING_POST_ORDER_OPEN_DATA = 8106;
static int EAStates::RECORDING_POST_ORDER_CLOSE_DATA = 8107;

// 8200s Are For Setup Related States
static int EAStates::CHECKING_FOR_SETUP = 8200;
static int EAStates::CHECKING_FOR_INVALID_SETUP = 8201;
static int EAStates::INVALIDATING_SETUP = 8202;
static int EAStates::CHECKING_IF_BROKE_RANGE_START = 8203;
static int EAStates::CHECKING_FOR_SAME_TYPE_SUBSEQUENT_MB = 8204;
static int EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC = 8205;
static int EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC = 8206;
static int EAStates::GETTING_NTH_MOST_RECENT_MB = 8207;

// 8300s Are For Confirmation Related States
static int EAStates::CHECKING_FOR_CONFIRMATION = 8300;
static int EAStates::CHECKING_FOR_MOST_RECENT_MB_PLUS_HOLDING_ZONE = 8301;