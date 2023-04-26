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

class Ticket : public BaseTicket
{
protected:
    int SelectTicket(string action);
    virtual int SelectIfOpen(string action);
    virtual int SelectIfClosed(string action);

public:
    Ticket() : BaseTicket() {}
    Ticket(int ticketNumber) : BaseTicket(ticketNumber) {}
    Ticket(Ticket &ticket) : BaseTicket(ticket) {}

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

    virtual int WasActivated(bool &active);

    virtual int Close();
    virtual int ClosePartial(double price, double lotSize);
};

int Ticket::SelectTicket(string action)
{
    int openSelectError = SelectIfOpen(action);
    if (openSelectError != Errors::ORDER_NOT_FOUND)
    {
        return Errors::NO_ERROR;
    }

    return SelectIfClosed(action);
}

int Ticket::SelectIfOpen(string action)
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

    if (OrderCloseTime() != 0)
    {
        return Errors::ORDER_IS_CLOSED;
    }

    return Errors::NO_ERROR;
}

int Ticket::SelectIfClosed(string action)
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

    if (OrderCloseTime() == 0)
    {
        return Errors::ORDER_IS_OPEN;
    }

    return Errors::NO_ERROR;
}

TicketType Ticket::Type()
{
    if (mType == TicketType::Buy || mType == TicketType::Sell)
    {
        return mType;
    }

    int selectError = SelectTicket("Getting Type");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Type",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return TicketType::Empty;
    }

    int type = OrderType();

    switch (type)
    {
    case OP_BUY:
        mType = TicketType::Buy;
        return mType;
    case OP_SELL:
        mType = TicketType::Sell;
        return mType;
    case OP_BUYLIMIT:
        return TicketType::BuyLimit;
    case OP_SELLLIMIT:
        return TicketType::SellLimit;
    case OP_BUYSTOP:
        return TicketType::BuyStop;
    case OP_SELLSTOP:
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

datetime Ticket::OpenTime()
{
    if (mOpenTime != 0)
    {
        return mOpenTime;
    }

    int selectError = SelectTicket("Retrieving Open Time");
    if (selectError != Errors::NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mOpenTime = OrderOpenTime();
    return mOpenTime;
}

double Ticket::LotSize()
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

double Ticket::CurrentStopLoss()
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

double Ticket::ClosePrice()
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

datetime Ticket::CloseTime()
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

double Ticket::TakeProfit()
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

datetime Ticket::Expiration()
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

double Ticket::Profit()
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

double Ticket::Commission()
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

int Ticket::WasActivated(bool &wasActivated)
{
    if (mWasActivated)
    {
        wasActivated = mWasActivated;
        return Errors::NO_ERROR;
    }

    int selectFromOpenOrdersError = SelectIfOpen("Checking if order is activated fallback open");
    if (selectFromOpenOrdersError != Errors::NO_ERROR)
    {
        // if we failed finding it we could have opened and closed the ticket between the last check.
        // If so we should check the closed tickets to see if our ticket is there
        int selectFromClosedOrdersError = SelectIfClosed("Checking if order is activated fallback closed");
        if (selectFromClosedOrdersError != Errors::NO_ERROR)
        {
            wasActivated = false;
            return selectFromClosedOrdersError;
        }
    }

    TicketType type = Type();
    mWasActivated = type == TicketType::Buy || type == TicketType::Sell;
    wasActivated = mWasActivated;

    return Errors::NO_ERROR;
}

int Ticket::Close()
{
    int selectOrderError = SelectIfOpen("Closing");
    if (selectOrderError != Errors::NO_ERROR)
    {
        return selectOrderError;
    }

    TicketType type = Type();

    // Active Order
    if (type == TicketType::Buy || type == TicketType::Sell)
    {
        RefreshRates();
        double closeAt = type == TicketType::Buy ? Bid : Ask;
        if (!OrderClose(mNumber, LotSize(), closeAt, 0, clrNONE))
        {
            Print("Failed to close. Type: ", type, ", Close At: ", closeAt);
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

int Ticket::ClosePartial(double price, double lotSize)
{
    int selectOrderError = SelectIfOpen("Closing");
    if (selectOrderError != Errors::NO_ERROR)
    {
        return selectOrderError;
    }

    TicketType type = Type();
    if (type != TicketType::Buy && type != TicketType::Sell)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (!OrderClose(mNumber, lotSize, price, 0, clrNONE))
    {
        return GetLastError();
    }

    return Errors::NO_ERROR;
}