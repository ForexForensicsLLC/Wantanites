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
    static int EAStates::CHECKING_TICKET;
    static int EAStates::SETTING_ACTIVE_TICKETS;
    static int EAStates::GETTING_CURRENT_TICK;

    // 8100s Are For Order Related States
    static int EAStates::CHECKING_IF_PENDING_ORDER;
    static int EAStates::CLOSING_PENDING_ORDER;
    static int EAStates::CHECKING_TO_EDIT_STOP_LOSS;
    static int EAStates::CHECKING_TO_TRAIL_STOP_LOSS;
    static int EAStates::COUNTING_OTHER_EA_ORDERS;
    static int EAStates::PLACING_ORDER;
    static int EAStates::RECORDING_ORDER_OPEN_DATA;
    static int EAStates::RECORDING_ORDER_CLOSE_DATA;
    static int EAStates::CHECKING_IF_TICKET_IS_ACTIVE;
    static int EAStates::CHECKING_IF_TICKET_IS_CLOSED;
    static int EAStates::CHECKING_TO_PLACE_ORDER;
    static int EAStates::RECORDING_PARTIAL_DATA;
    static int EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN;
    static int EAStates::CHECKING_PREVIOUS_SETUP_TICKET;
    static int EAStates::SETTING_OPEN_DATA_ON_TICKET;
    static int EAStates::CHECKING_TO_PARTIAL;
    static int EAStates::CHECKING_COVERING_COMMISSIONS;
    static int EAStates::MODIFYING_ORDER;
    static int EAStates::SEARCHING_FOR_PARTIALED_TICKET;

    // 8200s Are For Setup Related States
    static int EAStates::CHECKING_FOR_SETUP;
    static int EAStates::CHECKING_FOR_INVALID_SETUP;
    static int EAStates::INVALIDATING_SETUP;
    static int EAStates::CHECKING_IF_BROKE_RANGE_START;
    static int EAStates::CHECKING_FOR_SAME_TYPE_SUBSEQUENT_MB;
    static int EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;
    static int EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;
    static int EAStates::GETTING_NTH_MOST_RECENT_MB;
    static int EAStates::CHECKING_IF_MOST_RECENT_MB;
    static int EAStates::GETTING_FIRST_MB_IN_SETUP;
    static int EAStates::CHECKING_IF_BROKE_RANGE_END;
    static int EAStates::CHECKING_GETTING_SECOND_MB_IN_SETUP;
    static int EAStates::CHECKING_GETTING_LIQUIDATION_MB_IN_SETUP;
    static int EAStates::CHECKING_IF_SETUP_ZONE_IS_VALID_FOR_CONFIRMATION;
    static int EAStates::CHECKING_FOR_SINGLE_MB_SETUP;
    static int EAStates::CHECKING_FOR_DOUBLE_MB_SETUP;
    static int EAStates::CHECKING_FOR_LIQUIDATION_MB_SETUP;
    static int EAStates::MOVING_TO_BREAK_EVEN;

    // 8300s Are For Confirmation Related States
    static int EAStates::CHECKING_FOR_CONFIRMATION;
    static int EAStates::CHECKING_FOR_MOST_RECENT_MB_PLUS_HOLDING_ZONE;
    static int EAStates::CHECKING_IF_CONFIRMATION_IS_STILL_VALID;
};

// 8000s Are For General States
static int EAStates::CHECKING_IF_ALLOWED_TO_TRADE = 8000;
static int EAStates::FILLING_STRATEGY_MAGIC_NUMBERS = 8001;
static int EAStates::RESETING = 8002;
static int EAStates::ATTEMPTING_TO_MANAGE_ORDER = 8003;
static int EAStates::CHECKING_TICKET = 8004;
static int EAStates::SETTING_ACTIVE_TICKETS = 8005;
static int EAStates::GETTING_CURRENT_TICK = 8006;

// 8100s Are For Order Related States
static int EAStates::CHECKING_IF_PENDING_ORDER = 8100;
static int EAStates::CLOSING_PENDING_ORDER = 8101;
static int EAStates::CHECKING_TO_EDIT_STOP_LOSS = 8102;
static int EAStates::CHECKING_TO_TRAIL_STOP_LOSS = 8103;
static int EAStates::PLACING_ORDER = 8104;
static int EAStates::RECORDING_ORDER_OPEN_DATA = 8105;
static int EAStates::RECORDING_ORDER_CLOSE_DATA = 8106;
static int EAStates::CHECKING_IF_TICKET_IS_ACTIVE = 8107;
static int EAStates::CHECKING_IF_TICKET_IS_CLOSED = 8108;
static int EAStates::CHECKING_TO_PLACE_ORDER = 8109;
static int EAStates::RECORDING_PARTIAL_DATA = 8110;
static int EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN = 8111;
static int EAStates::CHECKING_PREVIOUS_SETUP_TICKET = 8112;
static int EAStates::SETTING_OPEN_DATA_ON_TICKET = 8113;
static int EAStates::CHECKING_TO_PARTIAL = 8114;
static int EAStates::COUNTING_OTHER_EA_ORDERS = 8115;
static int EAStates::MOVING_TO_BREAK_EVEN = 8116;
static int EAStates::CHECKING_COVERING_COMMISSIONS = 8117;
static int EAStates::MODIFYING_ORDER = 8118;
static int EAStates::SEARCHING_FOR_PARTIALED_TICKET = 8119;

// 8200s Are For Setup Related States
static int EAStates::CHECKING_FOR_SETUP = 8200;
static int EAStates::CHECKING_FOR_INVALID_SETUP = 8201;
static int EAStates::INVALIDATING_SETUP = 8202;
static int EAStates::CHECKING_IF_BROKE_RANGE_START = 8203;
static int EAStates::CHECKING_FOR_SAME_TYPE_SUBSEQUENT_MB = 8204;
static int EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC = 8205;
static int EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC = 8206;
static int EAStates::GETTING_NTH_MOST_RECENT_MB = 8207;
static int EAStates::CHECKING_IF_MOST_RECENT_MB = 8208;
static int EAStates::GETTING_FIRST_MB_IN_SETUP = 8209;
static int EAStates::CHECKING_IF_BROKE_RANGE_END = 8210;
static int EAStates::CHECKING_GETTING_SECOND_MB_IN_SETUP = 8211;
static int EAStates::CHECKING_GETTING_LIQUIDATION_MB_IN_SETUP = 8212;
static int EAStates::CHECKING_IF_SETUP_ZONE_IS_VALID_FOR_CONFIRMATION = 8213;
static int EAStates::CHECKING_FOR_SINGLE_MB_SETUP = 8214;
static int EAStates::CHECKING_FOR_DOUBLE_MB_SETUP = 8215;
static int EAStates::CHECKING_FOR_LIQUIDATION_MB_SETUP = 8216;

// 8300s Are For Confirmation Related States
static int EAStates::CHECKING_FOR_CONFIRMATION = 8300;
static int EAStates::CHECKING_FOR_MOST_RECENT_MB_PLUS_HOLDING_ZONE = 8301;
static int EAStates::CHECKING_IF_CONFIRMATION_IS_STILL_VALID = 8302;