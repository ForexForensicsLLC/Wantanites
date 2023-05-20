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

class TradeManager : public VersionSpecificTradeManager
{
private:
    bool StopLossPastEntry(TicketType ticketType, double entryPrice, double stopLoss);

public:
    TradeManager(ulong magicNumber, ulong slippage);
    ~TradeManager();

    double CleanLotSize(double dirtyLotSize);

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

bool TradeManager::StopLossPastEntry(TicketType ticketType, double entryPrice, double stopLoss)
{
    if ((ticketType == TicketType::Buy || ticketType == TicketType::BuyLimit || ticketType == TicketType::BuyStop) && stopLoss >= entryPrice)
    {
        return true;
    }

    if ((ticketType == TicketType::Sell || ticketType == TicketType::SellLimit || ticketType == TicketType::SellStop) && stopLoss <= entryPrice)
    {
        return true;
    }

    return false;
}

double TradeManager::CleanLotSize(double dirtyLotSize)
{
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    double maxLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double minLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);

    // cut off extra decimal places
    double cleanedLots = NormalizeDouble(dirtyLotSize, 2);
    // make sure we are not larger than the max
    cleanedLots = MathMin(cleanedLots, maxLotSize);
    // make sure we are not lower than the min
    cleanedLots = MathMax(cleanedLots, minLotSize);
    // make sure we have the correct step
    cleanedLots = MathRound(cleanedLots / lotStep) * lotStep;

    return cleanedLots;
}

int TradeManager::PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (ticketType != TicketType::Buy && ticketType != TicketType::Sell)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(ticketType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
        }
    }

    lots = CleanLotSize(lots);
    return VersionSpecificTradeManager::PlaceMarketOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (ticketType != TicketType::BuyLimit && ticketType != TicketType::SellLimit)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(ticketType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
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

    lots = CleanLotSize(lots);
    return VersionSpecificTradeManager::PlaceLimitOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (ticketType != TicketType::BuyStop && ticketType != TicketType::SellStop)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(ticketType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
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

    lots = CleanLotSize(lots);
    return VersionSpecificTradeManager::PlaceStopOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    return VersionSpecificTradeManager::ModifyOrder(ticket, entryPrice, stopLoss, takeProfit, expiration);
}