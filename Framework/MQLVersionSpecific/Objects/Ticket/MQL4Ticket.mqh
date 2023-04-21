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
    int SelectTicket(string action);
    virtual int SelectIfOpen(string action);
    virtual int SelectIfClosed(string action);

public:
    virtual OrderType Type();
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

int VersionSpecificTicket::SelectTicket(string action)
{
    int openSelectError = SelectIfOpen(action);
    if (openSelectError == Errors::NO_ERROR)
    {
        return Errors::NO_ERROR;
    }

    return SelectIfClosed(action);
}

int VersionSpecificTicket::SelectIfOpen(string action)
{
    if (!OrderSelect(mNumber, SELECT_BY_TICKET, MODE_TRADES))
    {
        bool found = false;
        for (int i = 0; i < OrdersTotal(); i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                int error = GetLastError();
                SendMail("Failed To Select Open Order By Position When " + action,
                         "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                             "Current Index: " + IntegerToString(i) + "\n" +
                             "Current Ticket: " + IntegerToString(mNumber) + "\n" +
                             "Error: " + IntegerToString(error));

                return error;
            }

            if (OrderTicket() == mNumber)
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
    if (!OrderSelect(mNumber, SELECT_BY_TICKET, MODE_HISTORY))
    {
        bool found = false;
        for (int i = 0; i < OrdersHistoryTotal(); i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
            {
                int error = GetLastError();
                SendMail("Failed To Select Closed Order By Position When " + action,
                         "Total Orders: " + IntegerToString(OrdersHistoryTotal()) + "\n" +
                             "Current Index: " + IntegerToString(i) + "\n" +
                             "Current Ticket: " + IntegerToString(mNumber) + "\n" +
                             "Error: " + IntegerToString(error));

                return error;
            }

            if (OrderTicket() == mNumber)
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

    int selectError = SelectTicket("Getting Type");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Type",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return OrderType::Empty;
    }

    int type = OrderType();
    switch (type)
    {
    case OP_BUY:
        mType = OrderType::Buy;
        return mType;
    case OP_SELL:
        mType = OrderType::Sell;
        return mType;
    case OP_BUYLIMIT:
        return OrderType::BuyLimit;
    case OP_SELLLIMIT:
        return OrderType::SellLimit;
    case OP_BUYSTOP:
        return OrderType::BuyStop;
    case OP_SELLSTOP:
        return OrderType::SellStop;
    default:
        return OrderType::Empty;
    }
}

double VersionSpecificTicket::OpenPrice()
{
    if (mOpenPrice != ConstantValues::EmptyDouble)
    {
        return mOpenPrice;
    }

    int selectError = SelectTicket("Retrieving Open Price");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    mOpenPrice = OrderOpenPrice();
    return mOpenPrice;
}

datetime VersionSpecificTicket::OpenTime()
{
    if (mOpenTime != EMPTY)
    {
        return mOpenTime;
    }

    int selectError = SelectTicket("Retrieving Open Time");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return EMPTY;
    }

    mOpenTime = OrderOpenTime();
    return mOpenTime;
}

double VersionSpecificTicket::LotSize()
{
    if (mLotSize != ConstantValues::EmptyDouble)
    {
        return mLotSize;
    }

    int selectError = SelectTicket("Retrieving Lot Size");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Lot Size",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    mLotSize = OrderLots();
    return mLotSize;
}

double VersionSpecificTicket::CurrentStopLoss()
{
    int selectError = SelectTicket("Retrieving Current StopLoss");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Current StopLoss",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    return OrderStopLoss();
}

double VersionSpecificTicket::ClosePrice()
{
    if (mClosePrice != ConstantValues::EmptyDouble)
    {
        return mClosePrice;
    }

    int selectError = SelectIfClosed("Retrieving Close Price");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Close Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    mClosePrice = OrderClosePrice();
    return mClosePrice;
}

datetime VersionSpecificTicket::CloseTime()
{
    if (mCloseTime != 0)
    {
        return mCloseTime;
    }

    int selectError = SelectIfClosed("Retrieving Close Time");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Close Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mCloseTime = OrderCloseTime();
    return mCloseTime;
}

double VersionSpecificTicket::TakeProfit()
{
    int selectError = SelectTicket("Retrieving Take Profit");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Take Profit",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    return OrderTakeProfit();
}

datetime VersionSpecificTicket::Expiration()
{
    int selectError = SelectTicket("Retrieving Expiration");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Expiration",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return EMPTY;
    }

    return OrderExpiration();
}

double VersionSpecificTicket::Profit()
{
    int selectError = SelectTicket("Retrieving Profit");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Profit",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    return OrderProfit();
}

double VersionSpecificTicket::Commission()
{
    if (mCommission != ConstantValues::EmptyDouble)
    {
        return mCommission;
    }

    int selectError = SelectTicket("Retrieving Commission");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Commission",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return ConstantValues::EmptyDouble;
    }

    return OrderCommission();
}

int VersionSpecificTicket::Close()
{
    int selectOrderError = SelectIfOpen("Closing");
    if (selectOrderError != Errors::NO_ERROR)
    {
        return selectOrderError;
    }

    OrderType type = Type();

    // Active Order
    if (type == OrderType::Buy || type == OrderType::Sell)
    {
        double closeAt = type == OrderType::Buy ? Bid : Ask;
        if (!OrderClose(mNumber, LotSize(), closeAt, 0, clrNONE))
        {
            return GetLastError();
        }
    }
    // Pending Order
    else
    {
        if (!OrderDelete(mNumber, clrNONE))
        {
            return GetLastError();
        }
    }

    mWasManuallyClosed = true;
    return Errors::NO_ERROR;
}