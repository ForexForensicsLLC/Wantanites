//+------------------------------------------------------------------+
//|                                              Summit Scalping.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

input double StopLossPadding = 50;
input double RiskPercent = 0.25;
input int PartialOneRR = 10;
input double PartialOnePercent = 0.8;


double MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
double Spread = MarketInfo(Symbol(), MODE_SPREAD);

double ContinuationSetUpRange = 0.0;
double ContinuationSetUpType = -1;

double ReversalSetUpRange = 0.0;
double ReversalSetUpType = -1;

double Continuations = 0.0;
double MinROCs = 0.0;

bool ContinuationSetUp = false; 
bool ReversalSetUp = false;
bool DoubleMBReversal = false;
double CrossedOpenPriceAfterMinROC = false;

int BullishMB = 0;
int BearishMB = 1;

int ContinuationMagicNumber = 111;
int ReversalMagicNumber = 222;

void OnTick()
  {
      // only trade for the New York Open
      double openPrice = iCustom(NULL, 0, "Min ROC. From Time", 0, 0);
      if (openPrice != NULL) 
      {
         double firstMBType = iCustom(); // most recent
         double secondMBType = iCustom(); // second most recent
         double thirdMBType = iCustom(); // third most recent
         
         // Any First Double MB Once 8:30 starts 
         if (MinROCs == 0 && Continuations < 2 && !ContinuationSetUp && firstMBType == secondMBType && secondMBType != thirdMBType) 
         {
           ContinuationSetUp = true;
           ContinuationSetUpRange = iCustom(); // get from SECOND MB from indicator
           ContinuationSetUpType = firstMBType;
           
           Continuations += 1;
           
           bool buying = (firstMBType == BullishMB);
           PlaceLimitOrders(buying, ContinuationMagicNumber);
         }
         
         // Cancel Orders if 3rd MB Prints
         if (ContinuationSetUp && thirdMBType == secondMBType)
         {
            CancelAllPendingOrders(ContinuationMagicNumber);
            MoveOrderToBreakEven(ContinuationMagicNumber);
            
            ContinuationSetUp = false;
         }
         
         // Range is Broken
         if (ContinuationSetUp && (ContinuationSetUpType == BullishMB && MathMin(Close[0], Low[0]) < ContinuationSetUpRange) || (ContinuationSetUpType == BearishMB && MathMax(Close[0], High[0]) > ContinuationSetUpRange))
         {
            ContinuationSetUp = false;
         }
               
         // Reversal
         double minROC = iCustom(NULL, 0, "Min ROC. From Time", 1, 0);
         if (minROC != NULL)
         {
            MinROCs += 1;
         }
         
         // first break after at least 1 Min ROC, wihtout crossing back over the open price or having a DoubleMBReversal yet
         if (!CrossedOpenPriceAfterMinROC && !DoubleMBReversal && MinROCs > 0 && firstMBType != secondMBType) 
         {
            ReversalSetUp = true;
            ReversalSetUpRange = iCustom(); // get from FIRST MB from indicator
            ReversalSetUpType = firstMBType;
            
            bool buying = firstMBType == BullishMB;
            PlaceLimitOrders(buying, ReversalMagicNumber); // going to have to handle placing orders in the first MB on the first break and then only placing orders in the second MB if it breaks down again
         }
         
         // Check to see if the reversal is a double MB reversal - We stop at after one of those
         if (ReversalSetUp && firstMBType == secondMBType)
         {
            DoubleMBReversal = true;
            
            bool buying = secondMBType == BullishMB;
            PlaceLimitOrders(buying, ReversalMagicNumber);
            
            // cancel any pending orders if a third MB prints
            if (secondMBType == thirdMBType) 
            {
               CancelAllPendingOrders(ReversalMagicNumber);
               MoveOrderToBreakEven(ReversalMagicNumber);
               
               ReversalSetUp = false;
            }
         }
         
         // Range is Broken
         if (ReversalSetUp && (ReversalSetUpType == BullishMB && MathMin(Close[0], Low[0]) < ReversalSetUpRange) || (ReversalSetUpType == BearishMB && MathMax(Close[0], High[0]) > ReversalSetUpRange))
         {
            ReversalSetUp = false;
         }
           
         if (MinROCs > 0 && ((Close[1] < openPrice && MathMax(Close[0], High[0]) > openPrice) || (Close[1] > openPrice && MathMin(Close[0], Low[0]) < openPrice)))
         {
            CrossedOpenPriceAfterMinROC = true;
         }
      }
      else
      {
         ContinuationSetUpRange = 0.0;
         ContinuationSetUpType = -1;
         
         ReversalSetUpRange = 0.0;
         ReversalSetUpType = -1;
         
         Continuations = 0;
         MinROCs = 0;
         
         ContinuationSetUp = false;
         ReversalSetUp = false;
         DoubleMBReversal = false;
         CrossedOpenPriceAfterMinROC = false;
      }
  }
  
void PlaceLimitOrders(bool buying, int magicNumber)
{
   for (int i = 0; i <= 5; i++) 
   {
      // could make it so imbalnces are stored in arrays, 1 for each MB, and are emptied after the 3rd MB or when price breaks the range? 
      double imbalanceOpen = iCustom();
      double imbalanceClose = iCustom(); 

      if (buying)
      {
         double stopLossPips = MathAbs(imbalanceOpen - imbalanceClose);               
         if(stopLossPips < MinStopLoss)
         {
            stopLossPips = MinStopLoss;
         }
         
         double lots = CalculateLotSize(stopLossPips);
         double stopLoss = imbalanceOpen - (stopLossPips + Spread + StopLossPadding);
         double takeProfit = imbalanceOpen + (stopLossPips * PartialOneRR);
         int firstOrderTicketNumber = OrderSend(NULL, OP_BUYLIMIT, lots * PartialOnePercent, imbalanceOpen, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);
         int secondOrderTicketNumber = OrderSend(NULL, OP_BUYLIMIT, lots * (1 - PartialOnePercent), imbalanceOpen, 0, stopLoss, NULL, NULL, magicNumber, 0, clrNONE);       
         
         if (firstOrderTicketNumber < 0)
         {          
            SendMail("Failed to place first Buy Limit", 
                    "Entry: " + DoubleToString(imbalanceOpen) + "\n" +
                    "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
                    "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
                    "Take Profit:" + DoubleToString(takeProfit) + "\n" + 
                    "Lots: " + DoubleToString(lots * PartialOnePercent) + "\n" + 
                    GetLastError());        
         }    
         
         if (secondOrderTicketNumber < 0)
         {
            SendMail("Failed to place second Buy Limit", 
                    "Entry: " + DoubleToString(imbalanceOpen) + "\n" +
                    "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
                    "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
                    "Lots: " + DoubleToString(lots * (1 - PartialOnePercent)) + "\n" + 
                    GetLastError());
         }
      }
      else 
      {
         double stopLossPips = MathAbs(imbalanceOpen - imbalanceClose);              
         if(stopLossPips < MinStopLoss)
         {
            stopLossPips = MinStopLoss;
         }
         
         double lots = CalculateLotSize(stopLossPips);
         double stopLoss = imbalanceOpen + (stopLossPips + Spread + StopLossPadding);
         double takeProfit = imbalanceOpen - (stopLossPips * PartialOneRR);
         int firstOrderTicketNumber = OrderSend(NULL, OP_SELLLIMIT, lots * PartialOnePercent, imbalanceOpen, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);  
         int secondOrderTicketNumber = OrderSend(NULL, OP_SELLLIMIT, lots * (1 - PartialOnePercent), imbalanceOpen, 0, stopLoss, NULL, NULL, magicNumber, 0, clrNONE);
              
         if (firstOrderTicketNumber < 0)
         {
            SendMail("Failed to place first Sell Limit", 
                    "Entry: " + DoubleToString(imbalanceOpen) + "\n" +
                    "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
                    "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
                    "Take Profit: " + DoubleToString(takeProfit) + "\n" +
                    "Lots: " + DoubleToString(lots * PartialOnePercent) + "\n" + 
                    GetLastError());
         }
         
         if (secondOrderTicketNumber < 0)
         {
            SendMail("Failed to place second Sell Limit", 
                    "Entry: " + DoubleToString(imbalanceOpen) + "\n" +
                    "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
                    "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
                    "Lots: " + DoubleToString(lots * (1 - PartialOnePercent)) + "\n" + 
                    GetLastError());
         }              
      }
   }
}

void CancelAllPendingLimitOrders(int magicNumber) 
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
      {
         SendMail("Failed To Select Order When Canceling",
                  "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                  "Current Order: " + IntegerToString(i) + "\n" +
                  GetLastError());
                  
      }
      
      if (OrderMagicNumber() == magicNumber && OrderType() > 1)
      {
         if (!OrderDelete(OrderTicket()))
         {
            SendMail("Failed To Delete Order", 
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Order: " + IntegerToString(i) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     GetLastError());
         }
      }
   }
}

void MoveOrderToBreakEven(int magicNumber)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS))
      {
         SendMail("Failed To Select Order When Moving To Break Even",
                  "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                  "Current Order: " + IntegerToString(i) + "\n" +
                  GetLastError());
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
                     GetLastError());
         }
      }
   }
}
  
double CalculateLotSize(double SLPips)
{          
   double LotSize = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5)){
      nTickValue = nTickValue * 10;
   }
   // We apply the formula to calculate the position size and assign the value to the variable.
   LotSize = (AccountBalance() * RiskPercent / 100) / (SLPips * nTickValue) / 100;
   return LotSize;
}