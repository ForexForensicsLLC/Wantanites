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

    virtual bool LotSizeIsInvalid(TicketType type, double entryPrice, double lotSize);

    virtual int PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    virtual int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
};

VersionSpecificTradeManager::VersionSpecificTradeManager(ulong magicNumber, ulong slippage)
{
    mMagicNumber = magicNumber;
    mSlippage = slippage;
}

VersionSpecificTradeManager::~VersionSpecificTradeManager() {}

bool VersionSpecificTradeManager::LotSizeIsInvalid(TicketType type, double entryPrice, double lotSize)
{
    int orderType;
    if (!TypeConverter::TicketTypeToOrderType(type, orderType))
    {
        return true;
    }

    double freeMargin = AccountFreeMarginCheck(Symbol(), orderType, lotSize);
    if (freeMargin <= 0)
    {
        Print("Not enough money to place order with a lotsize of ", lotSize);
        return true;
    }

    return false;
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