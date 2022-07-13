//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class OrderHelper
{
   private:
      static void SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber);
   public:
      // --- Calculating Orders ---
      static double RangeToPips(double range);
      static double PipsToRange(double pips);
      static double GetLotSize(double stopLossPips, double riskPercent);
      
      // --- Placing Orders ---
      static bool PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber);
      static bool PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber);
      
      // --- Managing Orders ---
      static bool CancelAllPendingOrdersByMagicNumber(int magicNumber);
      static bool MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber);
};
// ######################################################################
// ####################### Private Methods ##############################
// ######################################################################
static void OrderHelper::SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber)
{
   SendMail("Failed to place order",
      "Magic Number: " + IntegerToString(magicNumber) + "\n" +
      "Order Number: " + IntegerToString(orderNumber) + "\n" +
      "Type: " + IntegerToString(orderType) + "\n" +  
      "Ask: " + DoubleToString(Ask) + "\n" +
      "Bid: " + DoubleToString(Bid) + "\n" +
      "Entry: " + DoubleToString(entryPrice) + "\n" +
      "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
      // "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
      "Lots: " + DoubleToString(lots) + "\n" + 
      "Error: " + IntegerToString(GetLastError()));
}

// ######################################################################
// ####################### Public Methods ###############################
// ######################################################################
// ---------------- Calculating Orders ----------------------------------
// converts a range to pips
static double OrderHelper::RangeToPips(double range)
{
   // do Digits - 1 for pips otherwise it would be in pippetts
   return range * MathPow(10, Digits - 1);
}
// converts pips to a range
static double OrderHelper::PipsToRange(double pips)
{
   return pips / MathPow(10, Digits - 1);
}
static double OrderHelper::GetLotSize(double stopLossPips, double riskPercent)
{
   double LotSize = (AccountBalance() * riskPercent / 100) / stopLossPips / MarketInfo(Symbol(), MODE_LOTSIZE);
   
   return MathMax(LotSize, MarketInfo(Symbol(), MODE_MINLOT));
}
// ----------------- Placing Orders --------------------------------------
static bool OrderHelper::PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber = 0)
{ 
   bool allOrdersSucceeded = true;
   if (orderType != OP_BUYLIMIT && orderType != OP_SELLLIMIT)
   {
      Print("Wrong Order Type: ", IntegerToString(orderType));
      return false;
   }
   
   int firstOrderTicketNumber = OrderSend(NULL, orderType, NormalizeDouble(lots * (partialOnePercent / 100), 2), entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);
   int secondOrderTicketNumber = OrderSend(NULL, orderType, NormalizeDouble(lots * (1 - (partialOnePercent / 100)), 2), entryPrice, 0, stopLoss, NULL, NULL, magicNumber, 0, clrNONE);       
   
   if (firstOrderTicketNumber < 0)
   {              
      SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, NormalizeDouble(lots * (partialOnePercent / 100), 2), magicNumber);
      allOrdersSucceeded = false;    
   }    
   
   if (secondOrderTicketNumber < 0)
   {
      SendFailedOrderEMail(2, orderType, entryPrice, stopLoss, NormalizeDouble(lots * (1 - (partialOnePercent / 100)), 2), magicNumber);   
      allOrdersSucceeded = false;
   }
   
   return allOrdersSucceeded;
}

static bool OrderHelper::PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber)
{
   if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP)
   {
      Print("Wrong order type: ", IntegerToString(orderType));
      return false;
   }
   
   lots = NormalizeDouble(lots, 2);
   if (OrderSend(NULL, orderType, lots, entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE) < 0)
   {  
      SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber);
      return false;
   }
   
   return true;
}
// -------------------------- Managing Orders --------------------------------------
static bool OrderHelper::CancelAllPendingOrdersByMagicNumber(int magicNumber) 
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

static bool OrderHelper::MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber)
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

