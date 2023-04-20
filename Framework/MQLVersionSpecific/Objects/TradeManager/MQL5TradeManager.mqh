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

class TradeManager
{
private:
    CTrade trade;

    int CheckResult(int &ticket);

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
};

TradeManager::TradeManager(ulong magicNumber, ulong slippage)
{
    trade.SetExpertMagicNumber(magicNumber);
    trade.SetDeviationInPoints(slippage);
    trade.SetAsyncMode(false);
}

TradeManager::~TradeManager() {}

int VersionSpecificTradeManager::CheckResult(int &ticket)
{
    MqlTradeResult result;
    trade.Result(result);

    if (result.retcode == 10008)
    {
        if (result.deal > 0)
        {
            ticket = deal;
        }
        else if (result.order > 0)
        {
            ticket = order;
        }
    }

    return result.retcode;
}

int VersionSpecificTradeManager::Buy(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    trade.Buy(lots, Symbol(), entryPrice, stopLoss, takeProfit, "");
    return CheckResult(ticket);
}

int VersionSpecificTradeManager::Sell(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
}

int VersionSpecificTradeManager::BuyLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
}

int VersionSpecificTradeManager::SellLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
}

int VersionSpecificTradeManager::BuyStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
}

int VersionSpecificTradeManager::SellStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
}

int VersionSpecificTradeManager::OrderModify(int ticket, double entryPrice, double stopLoss, double takeProfit, datetime expiration)
{
}

int VersionSpecificTradeManager::OrderDelete(int ticket)
{
}

int VersionSpecificTradeManager::OrderClose(int ticket)
{
}