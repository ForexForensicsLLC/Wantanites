//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class VersionSpecificTradeManager
{
private:
    ulong mMagicNumber;
    ulong mSlippage;

    int PlaceMarketOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceLimitOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);
    int PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket);

public:
    VersionSpecificTradeManager(ulong magicNumber, ulong slippage);
    ~VersionSpecificTradeManager();

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

VersionSpecificTradeManager::VersionSpecificTradeManager(ulong magicNumber, ulong slippage)
{
    mMagicNumber = magicNumber;
    mSlippage = slippage;
}

VersionSpecificTradeManager::~VersionSpecificTradeManager() {}

int VersionSpecificTradeManager::PlaceMarketOrder(int orderType, double lots, double entry, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType >= 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    lots = CleanLotSize(lots);

    int newTicket = OrderSend(Symbol(), orderType, lots, entry, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);

    int error = ERR_NO_ERROR;
    if (newTicket == EMPTY)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entry, stopLoss, lots, magicNumber, error);
    }

    ticket = newTicket;
    return error;
}

int VersionSpecificTradeManager::PlaceLimitOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType != OP_BUYLIMIT && orderType != OP_SELLLIMIT)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if ((orderType == OP_BUYLIMIT && stopLoss >= entryPrice) || (orderType == OP_SELLLIMIT && stopLoss <= entryPrice))
        {
            return TerminalErrors::STOPLOSS_PAST_ENTRY;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((orderType == OP_BUYLIMIT && entryPrice >= currentTick.ask) || (orderType == OP_SELLLIMIT && entryPrice <= currentTick.bid))
    {
        return ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    lots = CleanLotSize(lots);

    int error = ERR_NO_ERROR;
    int ticketNumber = OrderSend(NULL, orderType, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    if (ticketNumber < 0)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, mMagicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

int VersionSpecificTradeManager::PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if (stopLoss > 0.0)
    {
        if ((orderType == OP_BUYSTOP && stopLoss >= entryPrice) || (orderType == OP_SELLSTOP && stopLoss <= entryPrice))
        {
            return TerminalErrors::STOPLOSS_PAST_ENTRY;
        }
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((orderType == OP_BUYSTOP && entryPrice <= currentTick.ask) || (orderType == OP_SELLSTOP && entryPrice >= currentTick.bid))
    {
        return ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    lots = CleanLotSize(lots);

    int error = ERR_NO_ERROR;
    int ticketNumber = OrderSend(NULL, orderType, lots, entryPrice, mSlippage, stopLoss, takeProfit, NULL, mMagicNumber, 0, clrNONE);

    if (ticketNumber < 0)
    {
        error = GetLastError();
        // SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

int VersionSpecificTradeManager::Buy(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceMarketOrder(OP_BUY, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int VersionSpecificTradeManager::Sell(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceMarketOrder(OP_SELL, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int VersionSpecificTradeManager::BuyLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceLimitOrder(OP_BUYLIMIT, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int VersionSpecificTradeManager::SellLimit(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceLimitOrder(OP_SELLLIMIT, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int VersionSpecificTradeManager::BuyStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceStopOrder(OP_BUYSTOP, lots, entryPrice, stopLoss, takeProfit, ticket);
}

int VersionSpecificTradeManager::SellStop(double lots, double entryPrice, double stopLoss, double takeProfit, int &ticket)
{
    return PlaceStopOrder(OP_SELLSTOP, lots, entryPrice, stopLoss, takeProfit, ticket);
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
