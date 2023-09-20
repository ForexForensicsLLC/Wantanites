//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Wantanites\Framework\Types\TicketTypes.mqh>
#include <Wantanites\Framework\Constants\ConstantValues.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Utilities\TypeConverter\TypeConverter.mqh>

class VersionSpecificTradeManager
{
private:
    CTrade trade;

    int CheckResult(int &ticket);

protected:
    VersionSpecificTradeManager(ulong magicNumber, ulong slippage);
    ~VersionSpecificTradeManager();

    virtual int CheckMargin(TicketType type, double entryPrice, double lotSize);

    virtual int PlaceMarketOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceLimitOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceStopOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    virtual int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
};

VersionSpecificTradeManager::VersionSpecificTradeManager(ulong magicNumber, ulong slippage)
{
    trade.SetExpertMagicNumber(magicNumber);
    trade.SetDeviationInPoints(slippage);
    trade.SetAsyncMode(false);
}

VersionSpecificTradeManager::~VersionSpecificTradeManager() {}

int VersionSpecificTradeManager::CheckResult(int &ticket)
{
    MqlTradeResult result;
    trade.Result(result);

    if (result.retcode >= 10008 && result.retcode <= 10010)
    {
        if (result.deal > 0)
        {
            ticket = result.deal;
        }
        else if (result.order > 0)
        {
            ticket = result.order;
        }
    }

    return result.retcode;
}

int VersionSpecificTradeManager::CheckMargin(TicketType type, double entryPrice, double lotSize)
{
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double marginRequired = ConstantValues::EmptyDouble;
    ENUM_ORDER_TYPE orderType;

    if (!TypeConverter::TicketTypeToOrderType(type, orderType))
    {
        return Errors::COULD_NOT_CONVERT_TYPE;
    }

    if (!OrderCalcMargin(orderType, Symbol(), lotSize, entryPrice, marginRequired))
    {
        return GetLastError();
    }

    if (marginRequired > freeMargin)
    {
        Print("Not enough money to place order with a lotsize of ", lotSize);
        return Errors::NOT_ENOUGH_MARGIN;
    }

    return Errors::NO_ERROR;
}

int VersionSpecificTradeManager::PlaceMarketOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    ticket = ConstantValues::EmptyInt;

    if (ticketType == TicketType::Buy)
    {
        trade.Buy(lotSize, Symbol(), entryPrice, stopLoss, takeProfit);
    }
    else if (ticketType == TicketType::Sell)
    {
        trade.Sell(lotSize, Symbol(), entryPrice, stopLoss, takeProfit);
    }

    return CheckResult(ticket);
}

int VersionSpecificTradeManager::PlaceLimitOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    ticket = ConstantValues::EmptyInt;

    if (ticketType == TicketType::BuyLimit)
    {
        trade.BuyLimit(lotSize, entryPrice, Symbol(), stopLoss, takeProfit);
    }
    else if (ticketType == TicketType::SellLimit)
    {
        trade.SellLimit(lotSize, entryPrice, Symbol(), stopLoss, takeProfit);
    }

    return CheckResult(ticket);
}

int VersionSpecificTradeManager::PlaceStopOrder(TicketType ticketType, double lotSize, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    ticket = ConstantValues::EmptyInt;

    if (ticketType == TicketType::BuyStop)
    {
        trade.BuyStop(lotSize, entryPrice, Symbol(), stopLoss, takeProfit);
    }
    else if (ticketType == TicketType::SellStop)
    {
        trade.SellStop(lotSize, entryPrice, Symbol(), stopLoss, takeProfit);
    }

    return CheckResult(ticket);
}

int VersionSpecificTradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    trade.OrderModify(ticket, entryPrice, stopLoss, takeProfit, ORDER_TIME_GTC, expiration);
    return CheckResult(ticket);
}