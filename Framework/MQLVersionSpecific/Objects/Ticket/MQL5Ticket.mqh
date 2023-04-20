//+------------------------------------------------------------------+
//|                                                       VersionSpecificTicket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\BaseTicket.mqh>

class VersionSpecificTicket : public BaseTicket
{
protected:
    virtual int SelectIfOpen(string action);
    virtual int SelectIfClosed(string action);

public:
    virtual OrderType Type();
    virtual double OpenPrice();
    virtual datetime OpenTime();
    virtual double LotSize();
    virtual double CurrentStopLoss();
    virtual double TakeProfit();
    virtual datetime Expiration();
    virtual double Profit();
    virtual double Commission();
};

int VersionSpecificTicket::SelectIfOpen(string action)
{
    if (!OrderSelect(mNumber))
    {
        bool found = false;
        for (int i = 0; i < OrdersTotal(); i++)
        {
            ulong ticket = OrderGetTicket(i);
            if (ticket <= 0)
            {
                continue;
            }

            if (OrderGetInteger(ORDER_TICKET) == mNumber)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            return Errors::ORDER_NOT_FOUND;
        }
    }

    return Errors::NO_ERROR;
}

int VersionSpecificTicket::SelectIfClosed(string action)
{
    if (!HistoryOrderSelect(mNumber))
    {
        bool found = false;
        for (int i = 0; i < HistoryOrdersTotal(); i++)
        {
            ulong ticket = HistoryOrderGetTicket(i);
            if (ticket <= 0)
            {
                continue;
            }

            if (HistoryOrderGetInteger(ORDER_TICKET) == mNumber)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            return Errors::ORDER_NOT_FOUND;
        }
    }

    return Errors::NO_ERROR;
}

OrderType VersionSpecificTicket::Type()
{
    if (mType == OrderType::Buy || mType == OrderType::Sell)
    {
        return mType;
    }

    ENUM_ORDER_TYPE type = NULL;
    int openSelectError = SelectIfOpen();
    if (openSelectError == Errors::NO_ERROR)
    {
        type = OrderGetInteger(ORDER_TYPE);
    }

    if (type == NULL)
    {
        int closedSelectError = SelectIfClosed();
        if (closedSelectError == Errors::NO_ERROR)
        {
            type = HistoryOrderGetInteger(ORDER_TYPE);
        }
    }

    if (type == NULL)
    {
        SendMail("Unable To Retrieve Type",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return OrderType::Empty;
    }

    switch (type)
    {
    case ORDER_TYPE_BUY:
        mType = OrderType::Buy;
        return mType;
    case ORDER_TYPE_SELL:
        mType = OrderType::Sell;
        return mType;
    case ORDER_TYPE_BUY_LIMIT:
        return OrderType::BuyLimit;
    case ORDER_TYPE_SELL_LIMIT:
        return OrderType::SellLimit;
    case ORDER_TYPE_BUY_STOP:
        return OrderType::BuyStop;
    case ORDER_TYPE_SELL_STOP:
        return OrderType::SellStop;
    default:
        return OrderType::Empty;
    }
}