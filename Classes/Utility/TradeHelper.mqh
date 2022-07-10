//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class TradeHelper
{
   public:
      static double GetLotSize(double stopLossPips, double riskPercent);
      static bool PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber);
      static bool CancelAllPendingLimitOrdersByMagicNumber(int magicNumber);
      static bool MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber);
};

static double TradeHelper::GetLotSize(double stopLossPips, double riskPercent)
{
   double LotSize = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5)){
      nTickValue = nTickValue * 10;
   }
   // We apply the formula to calculate the position size and assign the value to the variable.
   LotSize = (AccountBalance() * riskPercent / 100) / (stopLossPips * nTickValue) / 100;
   return LotSize;
}

static bool TradeHelper::PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber = 0)
{ 
   bool allOrdersSucceeded = true;
   if (orderType != OP_BUYLIMIT || OP_SELLLIMIT)
   {
      return false;
   }
   
   int firstOrderTicketNumber = OrderSend(NULL, OP_BUYLIMIT, lots * (partialOnePercent / 100), entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);
   int secondOrderTicketNumber = OrderSend(NULL, OP_BUYLIMIT, lots * (1 - (partialOnePercent / 100)), entryPrice, 0, stopLoss, NULL, NULL, magicNumber, 0, clrNONE);       
   
   if (firstOrderTicketNumber < 0)
   {          
      SendMail("Failed to place first Buy Limit", 
              "Entry: " + DoubleToString(entryPrice) + "\n" +
              "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
              // "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
              "Take Profit:" + DoubleToString(takeProfit) + "\n" + 
              "Lots: " + DoubleToString(lots * (partialOnePercent / 100)) + "\n" + 
              IntegerToString(GetLastError()));    
             
      allOrdersSucceeded = false;    
   }    
   
   if (secondOrderTicketNumber < 0)
   {
      SendMail("Failed to place second Buy Limit", 
              "Entry: " + DoubleToString(entryPrice) + "\n" +
              "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
              // "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
              "Lots: " + DoubleToString(lots * (1 - (partialOnePercent / 100))) + "\n" + 
              IntegerToString(GetLastError()));
       
      allOrdersSucceeded = false;
   }
   
   return allOrdersSucceeded;
}

static bool TradeHelper::CancelAllPendingLimitOrdersByMagicNumber(int magicNumber) 
{
   bool allCancelationsSucceeded = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
      {
         SendMail("Failed To Select Order When Canceling",
                  "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                  "Current Order: " + IntegerToString(i) + "\n" +
                  IntegerToString(GetLastError()));
                  
         allCancelationsSucceeded = false;
                  
      }
      
      if (OrderMagicNumber() == magicNumber && OrderType() > 1)
      {
         if (!OrderDelete(OrderTicket()))
         {
            SendMail("Failed To Delete Order", 
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Order: " + IntegerToString(i) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     IntegerToString(GetLastError()));
                     
            allCancelationsSucceeded = false;
         }
      }
   }
   
   return allCancelationsSucceeded;
}

static bool TradeHelper::MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber)
{
   bool allOrdersMoved = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
      {
         SendMail("Failed To Select Order When Moving To Break Even",
                  "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                  "Current Order: " + IntegerToString(i) + "\n" +
                  IntegerToString(GetLastError()));
                  
         allOrdersMoved = false;        
      }     
      
      // OP_BUY or OP_SELL
      if(OrderType() > 2 && OrderMagicNumber() == magicNumber)
      {
         if(!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration(), clrGreen))
         {          
            SendMail("Failed To Move Order To Break Even", 
               "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
               "Current Order: " + IntegerToString(i) + "\n" +
               "Open Price: " + DoubleToString(OrderOpenPrice()) + "\n" +
               "Stop Loss: " + DoubleToString(OrderStopLoss()) + "\n" +
               IntegerToString(GetLastError()));
         
            allOrdersMoved = false;                  
         }
      }
   }
   
   return allOrdersMoved;
}

