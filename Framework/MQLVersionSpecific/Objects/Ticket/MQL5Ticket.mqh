//+------------------------------------------------------------------+
//|                                                       Ticket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\BaseTicket.mqh>

enum PropertyType
{
    Integer,
    Double,
    String
};

class Ticket : public BaseTicket
{
private:
    void Init();

protected:
    ulong mPositionNumber;
    ulong mDealNumber;

    template <typename T>
    int GetProperty(PropertyType type, int property, T &value);

    virtual int SelectIfOpen(string action);
    virtual int SelectIfClosed(string action);

public:
    Ticket();
    Ticket(int ticketNumber);
    Ticket(Ticket &ticket);

    virtual ulong Number();
    virtual TicketType Type();
    virtual double OpenPrice();
    virtual datetime OpenTime();
    virtual double LotSize();
    virtual double CurrentStopLoss();
    virtual double ClosePrice();
    virtual datetime CloseTime();
    virtual double TakeProfit();
    virtual datetime Expiration();
    virtual double Profit();
    virtual double Commission();

    virtual int Close();
};

Ticket::Ticket() : BaseTicket()
{
    Init();
}

Ticket::Ticket(int ticketNumber) : BaseTicket(ticketNumber)
{
    Init();
}

Ticket::Ticket(Ticket &ticket) : BaseTicket(ticket)
{
    Init();
}

void Ticket::Init()
{
    mPositionNumber = ConstantValues::EmptyInt;
    mDealNumber = ConstantValues::EmptyInt;
}

template <typename T>
int Ticket::GetProperty(PropertyType type, int property, T &value)
{
    value = NULL;
    int openSelectError = SelectIfOpen("Getting Type");
    if (openSelectError == Errors::NO_ERROR)
    {
        switch (type)
        {
        case PropertyType::Integer:
            value = OrderGetInteger((ENUM_ORDER_PROPERTY_INTEGER)property);
            break;
        case PropertyType::Double:
            value = OrderGetDouble((ENUM_ORDER_PROPERTY_DOUBLE)property);
            break;
        case PropertyType::String:
            value = OrderGetString((ENUM_ORDER_PROPERTY_STRING)property);
            break;
        default:
            return Errors::WRONG_TYPE;
        }
    }

    if (property == NULL)
    {
        int closedSelectError = SelectIfClosed("Getting Type");
        if (closedSelectError == Errors::NO_ERROR)
        {
            switch (type)
            {
            case PropertyType::Integer:
                value = HistoryOrderGetInteger(Number(), (ENUM_ORDER_PROPERTY_INTEGER)property);
                break;
            case PropertyType::Double:
                value = HistoryOrderGetDouble(Number(), (ENUM_ORDER_PROPERTY_DOUBLE)property);
                break;
            case PropertyType::String:
                value = HistoryOrderGetString(Number(), (ENUM_ORDER_PROPERTY_STRING)property);
                break;
            default:
                return Errors::WRONG_TYPE;
            }
        }

        if (value == NULL)
        {
            SendMail("Unable To Retrieve Type",
                     "Error: " + IntegerToString(closedSelectError) + "\n" +
                         "Ticket Number: " + IntegerToString(mNumber));

            return closedSelectError;
        }
    }

    return Errors::NO_ERROR;
}

int Ticket::SelectIfOpen(string action)
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

            if (ticket == mNumber)
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

int Ticket::SelectIfClosed(string action)
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

            if (ticket == mNumber)
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

ulong Ticket::Number()
{
    return 0;
}

TicketType Ticket::Type()
{
    if (mType == TicketType::Buy || mType == TicketType::Sell)
    {
        return mType;
    }

    int type;
    int error = GetProperty<int>(PropertyType::Integer, ORDER_TYPE, type);
    if (error != Errors::NO_ERROR)
    {
        return TicketType::Empty;
    }

    switch ((ENUM_ORDER_TYPE)type)
    {
    case ORDER_TYPE_BUY:
        mType = TicketType::Buy;
        return mType;
    case ORDER_TYPE_SELL:
        mType = TicketType::Sell;
        return mType;
    case ORDER_TYPE_BUY_LIMIT:
        return TicketType::BuyLimit;
    case ORDER_TYPE_SELL_LIMIT:
        return TicketType::SellLimit;
    case ORDER_TYPE_BUY_STOP:
        return TicketType::BuyStop;
    case ORDER_TYPE_SELL_STOP:
        return TicketType::SellStop;
    default:
        return TicketType::Empty;
    }
}

double Ticket::OpenPrice()
{
    if (mOpenPrice != ConstantValues::EmptyDouble)
    {
        return mOpenPrice;
    }

    double openPrice;
    int error = GetProperty<double>(PropertyType::Double, ORDER_PRICE_CURRENT, openPrice);
    if (error != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    mOpenPrice = openPrice;
    return mOpenPrice;
}

datetime Ticket::OpenTime()
{
    if (mOpenTime != 0)
    {
        return mOpenTime;
    }

    datetime openTime;
    int error = GetProperty<datetime>(PropertyType::Integer, ORDER_TIME_SETUP, openTime);
    if (error != Errors::NO_ERROR)
    {
        return 0;
    }

    mOpenTime = openTime;
    return mOpenTime;
}

double Ticket::LotSize()
{
    if (mLotSize != ConstantValues::EmptyDouble)
    {
        return mLotSize;
    }

    double lotSize;
    int error = GetProperty<double>(PropertyType::Double, ORDER_VOLUME_CURRENT, lotSize);
    if (error != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    mLotSize = lotSize;
    return mLotSize;
}

double Ticket::CurrentStopLoss()
{
    double currentStopLoss;
    int error = GetProperty<double>(PropertyType::Double, ORDER_SL, currentStopLoss);
    if (error != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    return currentStopLoss;
}

double Ticket::ClosePrice()
{
    double currentStopLoss;
    int error = GetProperty<double>(PropertyType::Double, ORDER_SL, currentStopLoss);
    if (error != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    return currentStopLoss;
}

datetime Ticket::CloseTime()
{
    return 0;
}

double Ticket::TakeProfit()
{
    return 0;
}

datetime Ticket::Expiration()
{
    return 0;
}

double Ticket::Profit()
{
    return 0;
}

double Ticket::Commission()
{
    return 0;
}

int Ticket::Close()
{
    return 0;
}