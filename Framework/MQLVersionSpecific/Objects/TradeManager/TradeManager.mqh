//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Objects\TradeManager\MQL4TradeManager.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Objects\TradeManager\MQL5TradeManager.mqh>
#endif

#include <Wantanites\Framework\Utilities\PipConverter.mqh>

class TradeManager : public VersionSpecificTradeManager
{
private:
    int CheckStopLoss(TicketType ticketType, double entryPrice, double stopLoss);

public:
    TradeManager(ulong magicNumber, ulong slippage);
    ~TradeManager();

    virtual int CheckMargin(TicketType type, double entryPrice, double lotSize);

    virtual int PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    virtual int PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    virtual int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
};

TradeManager::TradeManager(ulong magicNumber, ulong slippage) : VersionSpecificTradeManager(magicNumber, slippage)
{
}

TradeManager::~TradeManager()
{
}

int TradeManager::CheckMargin(TicketType type, double entryPrice, double lotSize)
{
    return VersionSpecificTradeManager::CheckMargin(type, entryPrice, lotSize);
}

int TradeManager::CheckStopLoss(TicketType ticketType, double entryPrice, double stopLoss)
{
    if ((ticketType == TicketType::Buy || ticketType == TicketType::BuyLimit || ticketType == TicketType::BuyStop) && stopLoss >= entryPrice)
    {
        return Errors::STOPLOSS_PAST_ENTRY;
    }

    if ((ticketType == TicketType::Sell || ticketType == TicketType::SellLimit || ticketType == TicketType::SellStop) && stopLoss <= entryPrice)
    {
        return Errors::STOPLOSS_PAST_ENTRY;
    }

    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double normalised_price = round(MathAbs(entryPrice - stopLoss) / tickSize) * tickSize;
    int minStopLoss = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);

    if (minStopLoss > 0 && normalised_price <= (minStopLoss * _Point))
    {
        return Errors::STOP_LOSS_TOO_SMALL;
    }

    return Errors::NO_ERROR;
}

int TradeManager::PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int marginError = VersionSpecificTradeManager::CheckMargin(ticketType, entryPrice, lots);
    if (marginError != Errors::NO_ERROR)
    {
        return marginError;
    }

    if (ticketType != TicketType::Buy && ticketType != TicketType::Sell)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        int error = CheckStopLoss(ticketType, entryPrice, stopLoss);
        if (error != Errors::NO_ERROR)
        {
            return error;
        }
    }

    return VersionSpecificTradeManager::PlaceMarketOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int marginError = VersionSpecificTradeManager::CheckMargin(ticketType, entryPrice, lots);
    if (marginError != Errors::NO_ERROR)
    {
        return marginError;
    }

    if (ticketType != TicketType::BuyLimit && ticketType != TicketType::SellLimit)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        int error = CheckStopLoss(ticketType, entryPrice, stopLoss);
        if (error != Errors::NO_ERROR)
        {
            return error;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((ticketType == TicketType::BuyLimit && entryPrice >= currentTick.ask) || (ticketType == TicketType::SellLimit && entryPrice <= currentTick.bid))
    {
        return Errors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    return VersionSpecificTradeManager::PlaceLimitOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    int marginError = VersionSpecificTradeManager::CheckMargin(ticketType, entryPrice, lots);
    if (marginError != Errors::NO_ERROR)
    {
        return marginError;
    }

    if (ticketType != TicketType::BuyStop && ticketType != TicketType::SellStop)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        int error = CheckStopLoss(ticketType, entryPrice, stopLoss);
        if (error != Errors::NO_ERROR)
        {
            return error;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((ticketType == TicketType::BuyStop && entryPrice <= currentTick.ask) || (ticketType == TicketType::SellStop && entryPrice >= currentTick.bid))
    {
        return Errors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    return VersionSpecificTradeManager::PlaceStopOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    return VersionSpecificTradeManager::ModifyOrder(ticket, entryPrice, stopLoss, takeProfit, expiration);
}