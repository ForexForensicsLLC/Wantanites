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
    static bool TicketTypeToOrderType(TicketType type, int &orderType);
};

bool TypeConverter::TicketTypeToOrderType(TicketType ticketType, int &orderType)
{
    switch (ticketType)
    {
    case TicketType::Buy:
        orderType = OP_BUY;
        return true;
    case TicketType::Sell:
        orderType = OP_SELL;
        return true;
    case TicketType::BuyLimit:
        orderType = OP_BUYLIMIT;
        return true;
    case TicketType::SellLimit:
        orderType = OP_SELLLIMIT;
        return true;
    case TicketType::BuyStop:
        orderType = OP_BUYSTOP;
        return true;
    case TicketType::SellStop:
        orderType = OP_SELLSTOP;
        return true;
    default:
        return false;
    }
}
