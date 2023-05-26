//+------------------------------------------------------------------+
//|                                                     VersionSpecificOrderInfoHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\MailHelper.mqh>

class VersionSpecificOrderInfoHelper
{
public:
    static int TotalCurrentOrders();

    static int CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount);
    static int GetAllActiveTickets(List<int> &ticketNumbers);
    static int FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[]);
    static int FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket);
    static double GetTotalLotsForSymbolAndDirection(string symbol, TicketType type);
};

static int VersionSpecificOrderInfoHelper::TotalCurrentOrders()
{
    return OrdersTotal();
}

int VersionSpecificOrderInfoHelper::CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount)
{
    orderCount = 0;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        // only check current active tickets
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            MailHelper::Send("Failed To Select Open Order By Position When Counting Other EA Orders",
                             "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                                 "Current Order Index: " + IntegerToString(i) + "\n" +
                                 IntegerToString(error));
            return error;
        }

        for (int j = 0; j < magicNumbers.Size(); j++)
        {
            if (OrderMagicNumber() == magicNumbers[j])
            {
                datetime openDate = OrderOpenTime();
                if (todayOnly && (TimeYear(openDate) != Year() || TimeMonth(openDate) != Month() || TimeDay(openDate) != Day()))
                {
                    continue;
                }

                orderCount += 1;
            }
        }
    }

    return Errors::NO_ERROR;
}

int VersionSpecificOrderInfoHelper::GetAllActiveTickets(List<int> &ticketNumbers)
{
    int error = Errors::NO_ERROR;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            error = GetLastError();
            continue;
        }

        ticketNumbers.Add(OrderTicket());
    }

    return error;
}

int VersionSpecificOrderInfoHelper::FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[])
{
    ArrayFree(tickets);
    ArrayResize(tickets, 0);

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            MailHelper::Send("Failed To Select Open Order By Position When Finding Active Ticks",
                             "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                                 "Current Order Index: " + IntegerToString(i) + "\n" +
                                 IntegerToString(error));
            return error;
        }

        if (OrderMagicNumber() == magicNumber && OrderCloseTime() == 0)
        {
            ArrayResize(tickets, ArraySize(tickets) + 1);
            tickets[ArraySize(tickets) - 1] = OrderTicket();
        }
    }

    return Errors::NO_ERROR;
}

int VersionSpecificOrderInfoHelper::FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket)
{
    int error = Errors::NO_ERROR;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            error = GetLastError();
            MailHelper::Send("Failed To Select Order",
                             "Error: " + IntegerToString(error) + "\n" +
                                 "Position: " + IntegerToString(i) + "\n" +
                                 "Total Tickets: " + IntegerToString(OrdersTotal()));

            continue;
        }

        if (OrderType() > 1)
        {
            continue;
        }

        if (OrderMagicNumber() != magicNumber)
        {
            continue;
        }

        if (NormalizeDouble(OrderOpenPrice(), Digits) != NormalizeDouble(openPrice, Digits))
        {
            continue;
        }

        if (OrderOpenTime() != orderOpenTime)
        {
            continue;
        }

        ticket = OrderTicket();
        break;
    }

    return error;
}

double VersionSpecificOrderInfoHelper::GetTotalLotsForSymbolAndDirection(string symbol, TicketType type)
{
    double totalLots = 0;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            MailHelper::Send("Failed To Select Open Order By Position When Getting total lots",
                             "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                                 "Current Order Index: " + IntegerToString(i) + "\n" +
                                 IntegerToString(error));
            return error;
        }

        if (OrderSymbol() != symbol)
        {
            continue;
        }

        int orderType = OrderType();
        switch (type)
        {
        case TicketType::Buy:
        case TicketType::BuyStop:
        case TicketType::BuyLimit:
            if (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT)
            {
                totalLots += OrderLots();
            }

            break;
        case TicketType::Sell:
        case TicketType::SellStop:
        case TicketType::SellLimit:
            if (orderType == OP_SELL || orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT)
            {
                totalLots += OrderLots();
            }

            break;
        default:
            break;
        }
    }

    return totalLots;
}
