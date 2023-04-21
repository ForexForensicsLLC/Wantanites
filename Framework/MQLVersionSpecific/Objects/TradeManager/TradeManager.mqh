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

class TradeManager
{
private:
    VersionSpecificTradeManager *mTM;

    bool StopLossPastEntry(TicketType ticketType, double entryPrice, double stopLoss);

public:
    TradeManager(ulong magicNumber, ulong slippage);
    ~TradeManager();

    double CleanLotSize(double dirtyLotSize);

    int PlaceMarketOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceLimitOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceStopOrder(TicketType ticketType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    int ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
};

TradeManager::TradeManager(ulong magicNumber, ulong slippage)
{
    mTM = new VersionSpecificTradeManager(magicNumber, slippage);
}

TradeManager::~TradeManager()
{
    delete mTM;
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
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double maxLotSize = MarketInfo(Symbol(), MODE_MAXLOT);
    double minLotSize = MarketInfo(Symbol(), MODE_MINLOT);

    // cut off extra decimal places
    double cleanedLots = NormalizeDouble(dirtyLotSize, 2);

    // make sure we are not larger than the max
    cleanedLots = MathMin(cleanedLots, maxLotSize);
    // make sure we are not lower than the min
    cleanedLots = MathMax(cleanedLots, minLotSize);

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
    return mTM.PlaceMarketOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
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
    return mTM.PlaceLimitOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
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
    return mTM.PlaceStopOrder(ticketType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    return mTM.ModifyOrder(ticket, entryPrice, stopLoss, takeProfit, expiration);
}