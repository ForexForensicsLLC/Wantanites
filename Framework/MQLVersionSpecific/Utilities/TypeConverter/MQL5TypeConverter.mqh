//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class TypeConverter
{
public:
    static bool TicketTypeToOrderType(TicketType type, ENUM_ORDER_TYPE &orderType);
};

bool TypeConverter::TicketTypeToOrderType(TicketType ticketType, ENUM_ORDER_TYPE &orderType)
{
    switch (ticketType)
    {
    case TicketType::Buy:
        orderType = ORDER_TYPE_BUY;
        return true;
    case TicketType::Sell:
        orderType = ORDER_TYPE_SELL;
        return true;
    case TicketType::BuyLimit:
        orderType = ORDER_TYPE_BUY_LIMIT;
        return true;
    case TicketType::SellLimit:
        orderType = ORDER_TYPE_SELL_LIMIT;
        return true;
    case TicketType::BuyStop:
        orderType = ORDER_TYPE_BUY_STOP;
        return true;
    case TicketType::SellStop:
        orderType = ORDER_TYPE_SELL_STOP;
        return true;
    default:
        return false;
    }
}