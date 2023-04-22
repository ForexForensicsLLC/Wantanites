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

static int VersionSpecificOrderInfoHelper::CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount)
{
    // pending orders
    for (int i = 0; i < OrdersTotal(); i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket <= 0)
        {
            continue;
        }

        if (!OrderSelect(ticket))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Countint Other EA Orders",
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                         "Current Order Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        int magicNumber = OrderGetInteger(ORDER_MAGIC);
        for (int j = 0; j < magicNumbers.Size(); j++)
        {
            if (magicNumber == magicNumbers[j])
            {
                MqlDateTime currentTime = DateTimeHelper::CurrentTime();
                MqlDateTime openTime = DateTimeHelper::ToMQLDateTime(OrderGetInteger(ORDER_TIME_SETUP));

                if (todayOnly && (openTime.year != currentTime.year || openTime.mon != currentTime.mon || openTime.day != currentTime.day))
                {
                    continue;
                }

                orderCount += 1;
            }
        }
    }

    // active orders
    for (int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if (!PositionSelect(symbol))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Position By Symbol When Counting Other EA Orders",
                     "Total Positions: " + IntegerToString(PositionsTotal()) + "\n" +
                         "Current Position Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        int magicNumber = PositionGetInteger(POSITION_MAGIC);
        for (int j = 0; j < magicNumbers.Size(); j++)
        {
            if (magicNumber == magicNumbers[j])
            {
                MqlDateTime currentTime = DateTimeHelper::CurrentTime();
                MqlDateTime openTime = DateTimeHelper::ToMQLDateTime(PositionGetInteger(POSITION_TIME));

                if (todayOnly && (openTime.year != currentTime.year || openTime.mon != currentTime.mon || openTime.day != currentTime.day))
                {
                    continue;
                }

                orderCount += 1;
            }
        }
    }

    return Errors::NO_ERROR;
}

static int VersionSpecificOrderInfoHelper::FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[])
{
    // pending orders
    for (int i = 0; i < OrdersTotal(); i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket <= 0)
        {
            continue;
        }

        if (!OrderSelect(ticket))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Countint Other EA Orders",
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                         "Current Order Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        if (OrderGetInteger(ORDER_MAGIC) == magicNumber)
        {
            ArrayResize(tickets, ArraySize(tickets) + 1);
            tickets[ArraySize(tickets) - 1] = ticket;
        }
    }

    // active orders
    for (int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if (!PositionSelect(symbol))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Position By Symbol When Counting Other EA Orders",
                     "Total Positions: " + IntegerToString(PositionsTotal()) + "\n" +
                         "Current Position Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        if (PositionGetInteger(POSITION_MAGIC) == magicNumber)
        {
            ArrayResize(tickets, ArraySize(tickets) + 1);
            tickets[ArraySize(tickets) - 1] = PositionGetInteger(POSITION_TICKET);
        }
    }

    return Errors::NO_ERROR;
}

static int VersionSpecificOrderInfoHelper::FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket)
{
    int error = Errors::NO_ERROR;
    for (int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if (!PositionSelect(symbol))
        {
            error = GetLastError();
            SendMail("Failed To Select Open Position By Symbol When Counting Other EA Orders",
                     "Total Positions: " + IntegerToString(PositionsTotal()) + "\n" +
                         "Current Position Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            continue;
        }

        if (PositionGetInteger(POSITION_MAGIC) != magicNumber)
        {
            continue;
        }

        if (NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN), Digits()) != NormalizeDouble(openPrice, Digits()))
        {
            continue;
        }

        if (PositionGetInteger(POSITION_TIME) != orderOpenTime)
        {
            continue;
        }

        ticket = PositionGetInteger(POSITION_TICKET);
        break;
    }

    return error;
}
