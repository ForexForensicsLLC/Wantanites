//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Types\TicketTypes.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Utilities\TypeConverter\TypeConverter.mqh>

class VersionSpecificTradeManager
{
private:
    ulong mMagicNumber;
    ulong mSlippage;

protected:
    VersionSpecificTradeManager(ulong magicNumber, ulong slippage);
    ~VersionSpecificTradeManager();

    virtual int CheckMargin(TicketType type, double entryPrice, double lotSize);

    virtual int PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    virtual int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);

    virtual int CloseAllOppositeOrders(TicketType type);
};

VersionSpecificTradeManager::VersionSpecificTradeManager(ulong magicNumber, ulong slippage)
{
    mMagicNumber = magicNumber;
    mSlippage = slippage;
}

VersionSpecificTradeManager::~VersionSpecificTradeManager() {}

int VersionSpecificTradeManager::CheckMargin(TicketType type, double entryPrice, double lotSize)
{
    int orderType;
    if (!TypeConverter::TicketTypeToOPBuySell(type, orderType))
    {
        return Errors::COULD_NOT_CONVERT_TYPE;
    }

    double freeMargin = AccountFreeMarginCheck(Symbol(), orderType, lotSize);
    if (freeMargin <= 0)
    {
        Print("Not enough money to place order with a lotsize of ", lotSize);
        return Errors::NOT_ENOUGH_MARGIN;
    }

    return Errors::NO_ERROR;
}

int VersionSpecificTradeManager::PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int type = EMPTY;
    if (ticketType == TicketType::Buy)
    {
        type = OP_BUY;
    }
    else if (ticketType == TicketType::Sell)
    {
        type = OP_SELL;
    };

    int newTicket = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    int error = Errors::NO_ERROR;
    if (newTicket == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, ticketType, entry, stopLoss, lots, magicNumber, error);
    }

    ticket = newTicket;
    return error;
}

int VersionSpecificTradeManager::PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int type = EMPTY;
    if (ticketType == TicketType::BuyLimit)
    {
        type = OP_BUYLIMIT;
    }
    else if (ticketType == TicketType::SellLimit)
    {
        type = OP_SELLLIMIT;
    };

    int ticketNumber = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    int error = Errors::NO_ERROR;
    if (ticketNumber == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, ticketType, entryPrice, stopLoss, lots, mMagicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

int VersionSpecificTradeManager::PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    Print("Entry: ", entryPrice, ", SL: ", stopLoss, ", TP: ", takeProfit);
    int type = EMPTY;
    if (ticketType == TicketType::BuyStop)
    {
        type = OP_BUYSTOP;
    }
    else if (ticketType == TicketType::SellStop)
    {
        type = OP_SELLSTOP;
    };

    int error = Errors::NO_ERROR;
    int ticketNumber = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    if (ticketNumber == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, ticketType, entryPrice, stopLoss, lots, magicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

int VersionSpecificTradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    if (!OrderModify(ticket, entryPrice, stopLoss, takeProfit, "", clrNONE))
    {
        return GetLastError();
    }

    return Errors::NO_ERROR;
}

// TODO: Remove this method in favor of a shared trade manager so that both EAs can access each others tickets and close them if necessary
int VersionSpecificTradeManager::CloseAllOppositeOrders(TicketType type)
{
    int orderType;
    if (!TypeConverter::TicketTypeToOPBuySell(type, orderType))
    {
        return Errors::COULD_NOT_CONVERT_TYPE;
    }

    int error = Errors::NO_ERROR;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            error = GetLastError();
            continue;
        }

        int selectedOrderType = OrderType();
        if (orderType == OP_BUY && selectedOrderType == OP_SELL)
        {
            RefreshRates();
            if (!OrderClose(OrderTicket(), OrderLots(), Ask, 0, clrNONE))
            {
                error = GetLastError();
            }
        }
        else if (orderType == OP_SELL && selectedOrderType == OP_BUY)
        {
            RefreshRates();
            if (!OrderClose(OrderTicket(), OrderLots(), Bid, 0, clrNONE))
            {
                error = GetLastError();
            }
        }
    }
    return error;
}