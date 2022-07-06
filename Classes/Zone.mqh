//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class CZone
{
   private: 
   public:
      double Open;
      double Close;
      double WasRetrieved;
      
      CZone(double open, double close);
     ~CZone();
};

CZone::CZone(double open, double close)
{
   Open = open;
   Close = close;
   WasRetrieved = false;
}

CZone::~CZone()
{
}