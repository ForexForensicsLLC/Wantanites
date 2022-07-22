//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class OrderHelper
{
   private:
      // --- Error Handling ---
      static void SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber);
      
      // --- Selecting Orders ---
      static bool SelectOrderByPosition(int position, string action);
      static bool SelectOrderByTicket(int ticket, string action);
      
      // --- Calculating Orders Helpers ---
      static double GetEntryPriceForStopOrderOnMostRecentPendingMB(double spreadPips, int setupType, MBTracker* &mbt);
      static double GetStopLossForStopOrderOnMostRecentPendingMB(double paddingPips, double spreadPips, int setupType, MBTracker* &mbt);
      
      static double GetEntryPriceForStopOrderOnBreakOfMB(double spreadPips, int mbNumber, MBTracker* &mbt);
      static double GetStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker* &mbt);
      
   public:
      static const int EmptyTicket;
      // --- Calculating Orders ---
      static double RangeToPips(double range);
      static double PipsToRange(double pips);
      static double GetLotSize(double stopLossPips, double riskPercent);
      
      // --- Checking Orders ---
      static bool IsPendingOrder(int ticket);
      static int OtherEAOrders(int &magicNumbers[]);
      
      // --- Placing Orders ---
      static bool PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber);   
           
      static int PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber);
      static int PlaceStopOrderOnMostRecentPendingMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int setupMBNumber, MBTracker* &mbt);
      static int PlaceStopOrderOnBreakOfMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker* &mbt);
      
      // -- Editing Orders ---
      static bool EditStopLoss(double newStopLoss, double newLots, int magicNumber);
      static int CheckEditStopLossForMostRecentMBStopOrder(int ticket, double paddingPips, double spreadPips, double riskPercent, int setupMBNumber, MBTracker* &mbt);
      
      // --- Managing Orders ---
      static bool CancelAllPendingOrdersByMagicNumber(int magicNumber);
      static int CancelPendingOrderByTicket(int ticket);
      
      static bool MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber);
      
      // commenting out until I need it. Needs to be updated
      // static bool TrailAllOrdersToMBUpToBreakEven(int magicNumber, double paddingPips, double spreadPips, MBState* &mbState);
      static bool CheckTrailStopLossWithMBUpToBreakEven(int ticket, double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker* &mbt);
};
// ######################################################################
// ####################### Private Methods ##############################
// ######################################################################
// ------------------------ Error Handling ------------------------------
static const int OrderHelper::EmptyTicket = -1;

static void OrderHelper::SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber)
{
   SendMail("Failed to place order",
      "Time: " + IntegerToString(Hour())+ ":" + IntegerToString(Minute()) +":" + IntegerToString(Seconds()) + "\n" +
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

// --------------------- Selecting Orders ----------------------
static bool OrderHelper::SelectOrderByPosition(int position, string action)
{
   if (!OrderSelect(position, SELECT_BY_POS))
   {
      SendMail("Failed To Select Order By Position When " + action,
            "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
            "Current Order Index: " + IntegerToString(position) + "\n" +
            IntegerToString(GetLastError()));
      
      return false;
   }
   
   return true;
}   

static bool OrderHelper::SelectOrderByTicket(int ticket, string action)
{
   if (!OrderSelect(ticket, SELECT_BY_TICKET))
   {
      SendMail("Failed To Select Order By Ticket When " + action,
         "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
         "Current Ticket: " + IntegerToString(ticket) + "\n" +
         IntegerToString(GetLastError()));
      
      return false;
   }
   
   return true;
}
// ----------------- Calculating Orders Helpers --------------------------
static double OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(double spreadPips, int setupType, MBTracker* &mbt)
{ 
   double entryPrice = 0.0;
   if (setupType == OP_BUY)
   {
      int retracementIndex = mbt.CurrentBullishRetracementIndex();
      if (retracementIndex != -1)
      {  
         entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) + OrderHelper::PipsToRange(spreadPips);;             
      }        
   }
   else if (setupType == OP_SELL)
   {
      int retracementIndex = mbt.CurrentBearishRetracementIndex();
      if (retracementIndex != -1)
      {
         entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), retracementIndex);       
      }
   }
   
   return entryPrice;
}

static double OrderHelper::GetStopLossForStopOrderOnMostRecentPendingMB(double paddingPips, double spreadPips, int setupType, MBTracker* &mbt)
{
   double stopLoss = 0.0;
   if (setupType == OP_BUY)
   {
      int retracementIndex = mbt.CurrentBullishRetracementIndex();
      if (retracementIndex != -1)
      {  
         stopLoss = iLow(mbt.Symbol(), mbt.TimeFrame(), iLowest(mbt.Symbol(), mbt.TimeFrame(), MODE_LOW, retracementIndex, 0)) + PipsToRange(paddingPips);                    
      }        
   }
   else if (setupType == OP_SELL)
   {
      int retracementIndex = mbt.CurrentBearishRetracementIndex();
      if (retracementIndex != -1)
      {
         stopLoss = iHigh(mbt.Symbol(), mbt.TimeFrame(), iHighest(mbt.Symbol(), mbt.TimeFrame(), MODE_HIGH, retracementIndex, 0)) + PipsToRange(paddingPips) + PipsToRange(spreadPips);                     
      }
   }
   
   return stopLoss;
}

static double OrderHelper::GetEntryPriceForStopOrderOnBreakOfMB(double spreadPips, int mbNumber, MBTracker* &mbt)
{
   double entryPrice = 0.0;
   MBState* tempMBState;
   
   if (!mbt.GetMB(mbNumber, tempMBState))
   {
      return entryPrice;
   }
   
   if (tempMBState.Type() == OP_BUY)
   {
      entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex());
   }
   else if (tempMBState.Type() == OP_SELL)
   {
      entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex()) + PipsToRange(spreadPips); 
   }
   
   return entryPrice;
}

static double OrderHelper::GetStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker* &mbt)
{
   double stopLoss = 0.0;
   MBState* tempMBState;
   
   if (!mbt.GetMB(mbNumber, tempMBState))
   {
      return stopLoss;
   }
   
   if (tempMBState.Type() == OP_BUY)
   {
      stopLoss = iHigh(mbt.Symbol(), mbt.TimeFrame(), iHighest(mbt.Symbol(), mbt.TimeFrame(), MODE_HIGH, tempMBState.EndIndex(), 0)) + PipsToRange(paddingPips) + PipsToRange(spreadPips);
   }
   else if (tempMBState.Type() == OP_SELL)
   {
      stopLoss = iLow(mbt.Symbol(), mbt.TimeFrame(), iLowest(mbt.Symbol(), mbt.TimeFrame(), MODE_LOW, tempMBState.EndIndex(), 0)) + PipsToRange(paddingPips);
   }
   
   return stopLoss;
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
// ----------------- Checking Orders ------------------------------------
static bool OrderHelper::IsPendingOrder(int ticket)
{
   if (!SelectOrderByTicket(ticket, "Checking if Pending Order"))
   {
      return false;
   }
   
   // OP_BUY == 0, OP_SELL = 1, anything else is above 
   return OrderType() > 1;
}

static int OrderHelper::OtherEAOrders(int &magicNumbers[])
{
   int otherEAOrders = 0;
   for (int i = 0; i < OrdersTotal() - 1; i++)
   {
      if (!SelectOrderByPosition(i, "Checking if other EAs placed orders"))
      {
         continue;
      }
      
      for (int j = 0; j < ArraySize(magicNumbers) - 1; j++)
      {
         if (OrderMagicNumber() == magicNumbers[j])
         {
            otherEAOrders += 1;
         }
      }
   }
   
   return otherEAOrders;
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

static int OrderHelper::PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber)
{
   if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP)
   {
      Print("Wrong order type: ", IntegerToString(orderType));
      return EmptyTicket;
   }
   
   if ((orderType == OP_BUYSTOP && stopLoss >= entryPrice) || (orderType == OP_SELLSTOP && stopLoss <= entryPrice))
   {
      Print("Unable to place order with stop loss before entry");
      return EmptyTicket;
   }

   int ticket = OrderSend(NULL, orderType, lots, entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);
   if (ticket < 0)
   {
      SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber);
   }
   
   return ticket;
}

int OrderHelper::PlaceStopOrderOnMostRecentPendingMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int setupMBNumber, MBTracker* &mbt)
{
   MBState* tempMBState;
   if (!mbt.MBIsMostRecent(setupMBNumber, tempMBState))
   {
      return EmptyTicket;
   }
   
   int type = tempMBState.Type() + 4;
   double entryPrice = GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, tempMBState.Type(), mbt);
   double stopLoss = GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, tempMBState.Type(), mbt);
   double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
   
   return PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber); 
}

int OrderHelper::PlaceStopOrderOnBreakOfMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker* &mbt)
{
   MBState* tempMBState;
   if (!mbt.GetMB(mbNumber, tempMBState))
   {
      return EmptyTicket;
   }
   
   int type = -1;
   if (tempMBState.Type() == OP_BUY)
   {
      type = OP_SELLSTOP;
   }
   else if (tempMBState.Type() == OP_SELL)
   {
      type = OP_BUYSTOP;
   }
   
   double entryPrice = GetEntryPriceForStopOrderOnBreakOfMB(spreadPips, mbNumber, mbt);
   double stopLoss = GetStopLossForStopOrderOnBreakOfMB(paddingPips, spreadPips, mbNumber, mbt);
   double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
   
   return PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber);
}

// Edits the orders stop loss if it is different than the passed in stop loss
// Assumes that there will only ever be 1 pending order
static bool OrderHelper::EditStopLoss(double newStopLoss, double newLots, int magicNumber)
{
   if (OrdersTotal() == 1)
   {
      if (!SelectOrderByPosition(0, "Editing Stop Loss"))
      {
         return false;
      }
      
      if (OrderStopLoss() != newStopLoss)
      {        
         if (!CancelAllPendingOrdersByMagicNumber(magicNumber))
         {
            Print("Failed to delete order. Returning False");
            return false;
         }
         
         int type = OrderType();
         double entryPrice = OrderOpenPrice();
         double takeProfit = OrderTakeProfit();
         string comment = OrderComment();
         datetime expireation = OrderExpiration();
         
         Print("Re placing order with new stop loss");
         if (OrderSend(Symbol(), type, newLots, entryPrice, 0, newStopLoss, takeProfit, comment, magicNumber, expireation, clrNONE) < 0)
         {
            SendFailedOrderEMail(1, type, entryPrice, newStopLoss, newLots, magicNumber);
            return false;
         }
      }
   }
   
   return true;
}

static int OrderHelper::CheckEditStopLossForMostRecentMBStopOrder(int ticket, double paddingPips, double spreadPips, double riskPercent, int setupMBNumber, MBTracker* &mbt)
{
   if (!SelectOrderByTicket(ticket, "Editing Stop Loss"))
   {
      return EmptyTicket;
   }
   
   MBState* tempMBState;
   if (!mbt.GetMB(setupMBNumber, tempMBState))
   {
      return OrderTicket();
   }
   
   double newStopLoss = GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, tempMBState.Type(), mbt);    
   if (OrderStopLoss() == newStopLoss)
   {
      return OrderTicket();
   }
   
   int type = OrderType();
   double entryPrice = OrderOpenPrice();
   double takeProfit = OrderTakeProfit();
   string comment = OrderComment();
   int magicNumber = OrderMagicNumber();
   datetime expiration = OrderExpiration();
   
   if (!CancelAllPendingOrdersByMagicNumber(magicNumber))
   {
      return OrderTicket();
   }
   
   double newLots = GetLotSize(RangeToPips(MathAbs(entryPrice - newStopLoss)), riskPercent);
   int newTicket = OrderSend(Symbol(), type, newLots, OrderOpenPrice(), 0, newStopLoss, takeProfit, comment, magicNumber, expiration, clrNONE);
   if (newTicket < 0)
   {
      SendFailedOrderEMail(1, type, entryPrice, newStopLoss, newLots, magicNumber);
   }
   
   return newTicket;
}
// -------------------------- Managing Orders --------------------------------------
static bool OrderHelper::CancelAllPendingOrdersByMagicNumber(int magicNumber) 
{
   bool allCancelationsSucceeded = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!SelectOrderByPosition(i, "Canceling"))
      {
         allCancelationsSucceeded = false;
      }
      
      if (OrderMagicNumber() == magicNumber && OrderType() > 1)
      {
         if (!OrderDelete(OrderTicket()))
         {
            SendMail("Failed To Delete Order", 
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Order: " + IntegerToString(i) + "\n" +
                     "Current Ticket: " + IntegerToString(OrderTicket()) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     IntegerToString(GetLastError()));
                     
            allCancelationsSucceeded = false;
         }
      }
   }
   
   return allCancelationsSucceeded;
}

static int OrderHelper::CancelPendingOrderByTicket(int ticket)
{
   if (!OrderDelete(ticket))
   {
      SendMail("Failed To Delete Order", 
         "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
         "Ticket: " + IntegerToString(ticket) + "\n" +
         IntegerToString(GetLastError()));
      
      return ticket;
   }
   
   return EmptyTicket;
}

static bool OrderHelper::MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber)
{
   bool allOrdersMoved = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!SelectOrderByPosition(i, "Moving To Break Even"))
      {
         allOrdersMoved = false;
      }   
      
      // OP_BUY or OP_SELL
      if(OrderType() < 2 && OrderMagicNumber() == magicNumber)
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
/*
static bool OrderHelper::TrailAllOrdersToMBUpToBreakEven(int magicNumber, double paddingPips, double spreadPips, MBState* &mbState)
{
   bool allOrdersMoved = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!SelectOrderByPosition(i, "Trailing to MB up to Break Even"))
      {
         allOrdersMoved = false;
      }
      
      // OP_BUY or OP_SELL
      if(OrderType() < 2 && OrderMagicNumber() == magicNumber)
      {
         double currentStopLoss = OrderStopLoss();
         double newStopLoss = 0.0;
         
         if (mbState.Type() == OP_BUY)
         {
            newStopLoss = MathMin(
               OrderOpenPrice(), MathMax(
                  currentStopLoss, iLow(mbState.Symbol(), mbState.TimeFrame(), mbState.LowIndex()) - OrderHelper::PipsToRange(paddingPips)));
         }
         else if (mbState.Type() == OP_SELL)
         {
            newStopLoss = MathMax(
               OrderOpenPrice(), MathMin(
                  currentStopLoss, iHigh(mbState.Symbol(), mbState.TimeFrame(), mbState.HighIndex()) + OrderHelper::PipsToRange(paddingPips) + OrderHelper::PipsToRange(spreadPips)));
         }
         
         if (newStopLoss == currentStopLoss)
         {
            continue;
         }
         
         Print("Trailing - Current Stop Loss: ", currentStopLoss, ", New Stop Loss: ", newStopLoss);
         
         if(!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), OrderExpiration(), clrGreen))
         {          
            SendMail("Failed to trail stop loss",
               "Time: " + IntegerToString(Hour())+ ":" + IntegerToString(Minute()) +":" + IntegerToString(Seconds()) + "\n" +
               "Magic Number: " + IntegerToString(magicNumber) + "\n" +
               "Type: " + IntegerToString(OrderType()) + "\n" +  
               "Ask: " + DoubleToString(Ask) + "\n" +
               "Bid: " + DoubleToString(Bid) + "\n" +
               "Entry: " + DoubleToString(OrderOpenPrice()) + "\n" +
               "Current Stop Loss: " + DoubleToString(currentStopLoss) + "\n" +
               "New Stop Loss: " + DoubleToString(newStopLoss) + "\n" +
               "Error: " + IntegerToString(GetLastError()));
         
            allOrdersMoved = false;                  
         }
      }
   }
   
   return allOrdersMoved;
}
*/
static bool OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(int ticket, double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker* &mbt)
{
   if (!SelectOrderByTicket(ticket, "Tailing with MBs"))
   {
      return false;
   }
   
   if (OrderType() > 2)
   {
      return false;
   }
   
   MBState* tempMBState; 
   if (mbt.GetNthMostRecentMB(0, tempMBState) && tempMBState.Number() > setUpMB && tempMBState.Type() == setUpType)
   {
      double currentStopLoss = OrderStopLoss();
      double newStopLoss = 0.0;
      
      if (tempMBState.Type() == OP_BUY)
      {
         newStopLoss = MathMin(
            OrderOpenPrice(), MathMax(
               currentStopLoss, iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.LowIndex()) - OrderHelper::PipsToRange(paddingPips)));
      }
      else if (tempMBState.Type() == OP_SELL)
      {
         newStopLoss = MathMax(
            OrderOpenPrice(), MathMin(
               currentStopLoss, iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.HighIndex()) + OrderHelper::PipsToRange(paddingPips) + OrderHelper::PipsToRange(spreadPips)));
      }
      
      if (newStopLoss == currentStopLoss)
      {
         return false;;
      }
      
      Print("Trailing - Current Stop Loss: ", currentStopLoss, ", New Stop Loss: ", newStopLoss);
      
      if(!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), OrderExpiration(), clrGreen))
      {          
         SendMail("Failed to trail stop loss",
            "Time: " + IntegerToString(Hour())+ ":" + IntegerToString(Minute()) +":" + IntegerToString(Seconds()) + "\n" +
            "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
            "Type: " + IntegerToString(OrderType()) + "\n" +  
            "Ask: " + DoubleToString(Ask) + "\n" +
            "Bid: " + DoubleToString(Bid) + "\n" +
            "Entry: " + DoubleToString(OrderOpenPrice()) + "\n" +
            "Current Stop Loss: " + DoubleToString(currentStopLoss) + "\n" +
            "New Stop Loss: " + DoubleToString(newStopLoss) + "\n" +
            "Error: " + IntegerToString(GetLastError()));    
         
         return false;             
      }
   }
   
   return true;
}
