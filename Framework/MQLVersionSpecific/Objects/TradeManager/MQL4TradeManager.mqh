//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Types\OrderTypes.mqh>

class VersionSpecificTradeManager
{
private:
    ulong mMagicNumber;
    ulong mSlippage;

public:
    VersionSpecificTradeManager(ulong magicNumber, ulong slippage);
    ~VersionSpecificTradeManager();

    int PlaceMarketOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceLimitOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceStopOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
};

VersionSpecificTradeManager::VersionSpecificTradeManager(ulong magicNumber, ulong slippage)
{
    mMagicNumber = magicNumber;
    mSlippage = slippage;
}

VersionSpecificTradeManager::~VersionSpecificTradeManager() {}

int VersionSpecificTradeManager::PlaceMarketOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int type = EMPTY;
    if (orderType == OrderType::Buy)
    {
        type = OP_BUY;
    }
    else if (orderType == OrderType::Sell)
    {
        type = OP_SELL;
    };

    int newTicket = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    int error = Errors::NO_ERROR;
    if (newTicket == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entry, stopLoss, lots, magicNumber, error);
    }

    ticket = newTicket;
    return error;
}

int VersionSpecificTradeManager::PlaceLimitOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int type = EMPTY;
    if (orderType == OrderType::BuyLimit)
    {
        type = OP_BUYLIMIT;
    }
    else if (orderType == OrderType::SellLimit)
    {
        type = OP_SELLLIMIT;
    };

    int ticketNumber = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    int error = Errors::NO_ERROR;
    if (ticketNumber == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, mMagicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

int VersionSpecificTradeManager::PlaceStopOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int type = EMPTY;
    if (orderType == OrderType::BuyStop)
    {
        type = OP_BUYSTOP;
    }
    else if (orderType == OrderType::SellStop)
    {
        type = OP_SELLSTOP;
    };

    int error = Errors::NO_ERROR;
    int ticketNumber = OrderSend(Symbol(), type, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    if (ticketNumber == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber, error);
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