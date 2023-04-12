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
#include <Wantanites\Framework\MQLVersionSpecific\Utilities\TradeManager\MQL4TradeManager.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Utilities\TradeManager\MQL5TradeManager.mqh>
#endif

#include <Wantanites\Framework\Constants\OrderTypes.mqh>

class TradeManager
{
private:
    VersionSpecificTradeManager *mTM;

public:
    TradeManager(ulong magicNumber, ulong slippage);
    ~TradeManager();

    int Buy(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int Sell(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int BuyLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int SellLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int BuyStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int SellStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

    int OrderModify(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration);
    int OrderDelete(int ticket);
    int OrderClose(int ticket);
};

TradeManager::TradeManager(ulong magicNumber, ulong slippage)
{
    mTM = new VersionSpecificTradeManager(magicNumber, slippage);
}

TradeManager::~TradeManager() {}

int TradeManager::Buy(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.Buy(lots, entryPrice, stopLoss, takeProfit, ticket);
}
int TradeManager::Sell(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.Sell(lots, entryPrice, stopLoss, takeProfit, ticket);
}
int TradeManager::BuyLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.BuyLimit(lots, entryPrice, stopLoss, takeProfit, ticket);
}
int TradeManager::SellLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.SellLimit(lots, entryPrice, stopLoss, takeProfit, ticket);
}
int TradeManager::BuyStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.BuyStop(lots, entryPrice, stopLoss, takeProfit, ticket);
}
int TradeManager::SellStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return mTM.SellStop(lots, entryPrice, stopLoss, takeProfit, ticket);
}

int TradeManager::OrderModify(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
    return mTM.OrderModify(ticket, entryPrice, stopLoss, takeProfit, expiration);
}

int TradeManager::OrderDelete(int ticket)
{
    return mTM.OrderDelete(ticket);
}

int TradeManager::OrderClose(int ticket)
{
    return mTM.OrderClose(ticet);
}