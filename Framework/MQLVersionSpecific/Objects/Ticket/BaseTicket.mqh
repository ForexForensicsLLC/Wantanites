//+------------------------------------------------------------------+
//|                                                       BaseTicket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Types\TicketTypes.mqh>

class BaseTicket
{
protected:
    ulong mNumber;
    TicketType mType; // type doesn't change after it has become a normal Buy or Sell order
    double mOpenPrice;
    datetime mOpenTime;
    double mLotSize; // lot size can't change. If a ticket is partialed you get a new ticket
    double mClosePrice;
    datetime mCloseTime;
    double mCommission;

    bool mWasManuallyClosed;

    virtual int SelectIfOpen(string action) = NULL;
    virtual int SelectIfClosed(string action) = NULL;

public:
    ulong Number() { return mNumber; }
    virtual TicketType Type() = NULL;
    virtual double OpenPrice() = NULL;
    virtual datetime OpenTime() = NULL;
    virtual double LotSize() = NULL;
    virtual double CurrentStopLoss() = NULL;
    virtual double ClosePrice() = NULL;
    virtual datetime CloseTime() = NULL;
    virtual double TakeProfit() = NULL;
    virtual datetime Expiration() = NULL;
    virtual double Profit() = NULL;
    virtual double Commission() = NULL;

    virtual int Close() = NULL;
};
