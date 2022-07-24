//+------------------------------------------------------------------+
//|                                                          IEA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property strict

interface IEA
{
    void Manage();
    void CheckInvalidateSetup();
    bool AllowedToTrade();
    bool Confirmation();
    void PlaceOrders();
    void CheckSetSetup();
    void Reset();
    void Run();
};
