//+------------------------------------------------------------------+
//|                                                     VersionSpecificOrderInfoHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class VersionSpecificOrderInfoHelper
{
public:
    static int CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount);
    static int FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[]);
    static int FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket);
};

int VersionSpecificOrderInfoHelper::CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount)
{
    orderCount = 0;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        // only check current active tickets
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Countint Other EA Orders",
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

int VersionSpecificOrderInfoHelper::FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[])
{
    ArrayFree(tickets);
    ArrayResize(tickets, 0);

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Finding Active Ticks",
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
            SendMail("Failed To Select Order",
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