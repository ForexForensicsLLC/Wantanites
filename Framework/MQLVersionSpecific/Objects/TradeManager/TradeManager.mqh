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

    bool StopLossPastEntry(OrderType orderType, double entryPrice, double stopLoss);

public:
    TradeManager(ulong magicNumber, ulong slippage);
    ~TradeManager();

    double CleanLotSize(double dirtyLotSize);

    int PlaceMarketOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceLimitOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceStopOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

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

bool TradeManager::StopLossPastEntry(OrderType orderType, double entryPrice, double stopLoss)
{
    if ((orderType == OrderType::Buy || orderType == OrderType::BuyLimit || orderType == OrderType::BuyStop) && stopLoss >= entryPrice)
    {
        return true;
    }

    if ((orderType == OrderType::Sell || orderType == OrderType::SellLimit || orderType == OrderType::SellStop) && stopLoss <= entryPrice)
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

int TradeManager::PlaceMarketOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType != OrderType::Buy && orderType != OrderType::Sell)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(orderType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
        }
    }

    lots = CleanLotSize(lots);
    return mTM.PlaceMarketOrder(orderType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceLimitOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType != OrderType::BuyLimit && orderType != OrderType::SellLimit)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(orderType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((orderType == OrderType::BuyLimit && entryPrice >= currentTick.ask) || (orderType == OrderType::SellLimit && entryPrice <= currentTick.bid))
    {
        return Errors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    lots = CleanLotSize(lots);
    return mTM.PlaceLimitOrder(orderType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::PlaceStopOrder(OrderType orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType != OrderType::BuyStop && orderType != OrderType::SellStop)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if (StopLossPastEntry(orderType, entryPrice, stopLoss))
        {
            return Errors::STOPLOSS_PAST_ENTRY;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((orderType == OrderType::BuyStop && entryPrice <= currentTick.ask) || (orderType == OrderType::SellStop && entryPrice >= currentTick.bid))
    {
        return Errors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    lots = CleanLotSize(lots);
    return mTM.PlaceStopOrder(orderType, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::ModifyOrder(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    return mTM.ModifyOrder(ticket, entryPrice, stopLoss, takeProfit, expiration);
}