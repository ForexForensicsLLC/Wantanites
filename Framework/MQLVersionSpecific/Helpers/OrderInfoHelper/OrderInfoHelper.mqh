//+------------------------------------------------------------------+
//|                                                     OrderInfoHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\OrderInfoHelper\MQL4OrderInfoHelper.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\OrderInfoHelper\MQL5OrderInfoHelper.mqh>
#endif

class OrderInfoHelper
{
public:
    static int TotalCurrentOrders();

    static int CountOtherEAOrders(bool todayOnly, List<int> &magicNumber, int &orderCount);
    static int GetAllActiveTickets(List<int> &ticketNumbers);
    static int FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[]);
    static int FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket);
};

int OrderInfoHelper::TotalCurrentOrders()
{
    return VersionSpecificOrderInfoHelper::TotalCurrentOrders();
}

int OrderInfoHelper::CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount)
{
    return VersionSpecificOrderInfoHelper::CountOtherEAOrders(todayOnly, magicNumbers, orderCount);
}

int OrderInfoHelper::GetAllActiveTickets(List<int> &ticketNumbers)
{
    return VersionSpecificOrderInfoHelper::GetAllActiveTickets(ticketNumbers);
}

int OrderInfoHelper::FindActiveTicketsByMagicNumber(int magicNumber, int &tickets[])
{
    return VersionSpecificOrderInfoHelper::FindActiveTicketsByMagicNumber(magicNumber, tickets);
}

int OrderInfoHelper::FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket)
{
    return VersionSpecificOrderInfoHelper::FindNewTicketAfterPartial(magicNumber, openPrice, orderOpenTime, ticket);
}