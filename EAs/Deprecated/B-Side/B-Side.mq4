//+------------------------------------------------------------------+
//|                                                     Template.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

//Make sure path is correct
#include <WantaCapital\Framework\Trackers\MBTracker.mqh>
#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 7;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 50;

// -- MBTracker Inputs ---
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = true;

// --- Min ROC. Inputs ---
input int ServerHourStartTime = 16; 
input int ServerMinuteStartTime = 30;
input int ServerHourEndTime = 16 ; 
input int ServerMinuteEndTime = 33;
input double MinROCPercent = 0.18;

// --- EA Constants ---
double const MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
int const MBsNeeded = 2;
int const MagicNumber = 10002;
int const MaxTradesPerDay = 10;
int const MaxSpreadPips = 7; 

// --- EA Globals ---
MBTracker* MBT;
MBState* MBSetUpStates[];
ZoneState* ZoneStates[];

datetime MinROCTime = NULL;

double SetUpRangeStart = -1.0;
//double SetUpRangeEnd = -1.0;
int SetUpType = -1;

bool SingleMBSetUp = false;
bool DoubleMBSetUp = false;

int MBOneNumber = -1;
int MBTwoNumber = -1;

bool StopTrading = false;
bool CanceledAllPendingOrders = false;

int OnInit()
{
   MathSrand(MagicNumber);
   
   MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors);
   
   ArrayResize(MBSetUpStates, MBsNeeded);
   ArrayResize(ZoneStates, MaxZonesInMB);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("Deiniting");
   
   delete MBT;
}

void OnTick()
{
   MBT.DrawNMostRecentMBs(-1);
   MBT.DrawZonesForNMostRecentMBs(-1);
   
   if (StopTrading)
   {
      Print("Stop Trading");
   }
   
   if (OrdersTotal() > 0)
   {
      MBState* mbState; 
      if (MBT.GetNthMostRecentMB(0, mbState) && mbState.Number() > MBOneNumber && mbState.Number() > MBTwoNumber && mbState.Type() == SetUpType)
      {
         // TODO: Add Spread Back
         OrderHelper::TrailAllOrdersToMBUpToBreakEven(MagicNumber, 0, 0, mbState);
         
      }
      
      if (!CanceledAllPendingOrders)
      {
         bool tripleMB = MBT.HasNMostRecentConsecutiveMBs(3);
         bool liquidatedSecondAndContinued = DoubleMBSetUp && MBT.NthMostRecentMBIsOpposite(0) && MBT.NthMostRecentMBIsOpposite(1);
                
         //Print("Checking to cancel");
         // Stop trading for the day
         if (tripleMB || liquidatedSecondAndContinued)
         {
            Print("Canceling");
            StopTrading = true;
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            CanceledAllPendingOrders = true;
         }
      }
   }
   
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) / 10;
   double openPrice  = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
   
   // only trade if spread is below the allow maximum and if it is within our trading time 
   if (openPrice != NULL)
   {
      if (currentSpread <= MaxSpreadPips)
      {
         bool brokeStartRange = (SetUpType == OP_BUY && Close[0] < SetUpRangeStart) || (SetUpType == OP_SELL && Close[0] > SetUpRangeStart);
         bool crossedOpenPrice = (Close[1] < openPrice && MathMax(Close[0], High[0]) > openPrice) || (Close[1] > openPrice && MathMin(Close[0], Low[0]) < openPrice);
         
         if (MinROCTime != NULL && (crossedOpenPrice || brokeStartRange))
         {                     
            StopTrading = true;
         }
         
         if (!StopTrading)
         {
            double minRateOfChange = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 1, 0);
            if (minRateOfChange != NULL && MinROCTime == NULL)
            { 
               MinROCTime = iTime(Symbol(), Period(), 0);
            }
            
            // if we've had a Min ROC and hven't had a setup yet, and the current MB just broke structure
            if (MinROCTime != NULL && !SingleMBSetUp && !DoubleMBSetUp && MBT.NthMostRecentMBIsOpposite(0, MBSetUpStates))
            {
               // only if the setup happened during our session
               if (iTime(Symbol(), Period(), MBSetUpStates[0].EndIndex()) >= MinROCTime)
               {
                  MBState* tempMBState;
                  if (MBT.GetNthMostRecentMB(1, tempMBState))
                  {
                     bool bothAbove = iClose(Symbol(), Period(), tempMBState.StartIndex()) > openPrice && iClose(Symbol(), Period(), MBSetUpStates[0].StartIndex()) > openPrice;
                     bool bothBelow = iClose(Symbol(), Period(), tempMBState.StartIndex()) < openPrice && iClose(Symbol(), Period(), MBSetUpStates[0].StartIndex()) < openPrice;
                     
                     bool breakingUp = bothBelow && MBSetUpStates[0].Type() == OP_BUY;
                     bool breakingDown = bothAbove && MBSetUpStates[0].Type() == OP_SELL;
                     
                     if (breakingUp || breakingDown)
                     {
                        SingleMBSetUp = true;       
                        Print("Single MB Set Up");
                        // store type and range end for ease of access later 
                        SetUpType = MBSetUpStates[0].Type();
                        MBOneNumber = MBSetUpStates[0].Number();
                        
                        if (SetUpType == OP_BUY)
                        {
                           SetUpRangeStart = iLow(Symbol(), Period(), MBSetUpStates[0].LowIndex());
                        }
                        else if (SetUpType == OP_SELL)
                        {
                           SetUpRangeStart = iHigh(Symbol(), Period(), MBSetUpStates[0].HighIndex());
                        }
                        
                        // place orders on the zones of the first MB
                        if (MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
                        {
                           PlaceLimitOrders();
                        }
                     }
                  }
               }
               
               ClearMBs();
               ClearZones();
            }   
            
            // if we've had a min roc and a single MB break down and a second has just continuted structure
            // TODO FIX: This will continue to place orders in the first setups zones until there is a second setup
            if (MinROCTime != NULL && SingleMBSetUp && !DoubleMBSetUp && MBT.HasNMostRecentConsecutiveMBs(2, MBSetUpStates))
            {
               Print("Double MB Setup");
               DoubleMBSetUp = true;             
               
               MBTwoNumber = MBSetUpStates[0].Number();
               // place orders on the zones of the second MB
               if (MBT.GetNthMostRecentMBsUnretrievedZones(1, ZoneStates))
               {
                  PlaceLimitOrders();
               }
               
               ClearMBs();
               ClearZones();
            }
            
            // check for any zones that may have printed after the second MB was validated
            MBState* tempMBState;
            if (MinROCTime != NULL && (SingleMBSetUp || DoubleMBSetUp) && MBT.GetNthMostRecentMB(0, tempMBState))
            {
               if ((tempMBState.Number() == MBOneNumber || tempMBState.Number() == MBTwoNumber) && MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
               {
                  Print("Found zones after validation");
                  PlaceLimitOrders();       
                  ClearZones();
               }
               
               ClearMBs();
            }
         }
      }
   }
   else
   {
      MinROCTime = NULL;
      StopTrading = false;
      
      SetUpRangeStart = -1.0;
      SetUpType = -1;
      
      SingleMBSetUp = false;
      DoubleMBSetUp = false;
      
      MBOneNumber = -1;
      MBTwoNumber = -1;
      
      // TradeHelper::RecordTradesForToday(MagicNumber);
   }
}

void PlaceLimitOrders()
{
   for (int i = 0; i < MaxZonesInMB; i++)
   {
      if (CheckPointer(ZoneStates[i]) == POINTER_INVALID)
      {
         continue;
      }   
      
      Print("Zone Entry: ", ZoneStates[i].EntryPrice(), ", Zone Exit: ", ZoneStates[i].ExitPrice());
      
      int orderType = SetUpType + 2;
      
      double entryPrice = 0.0;
      double stopLossRange = 0.0;
      double stopLoss = 0.0;
      double takeProfit = 0.0;
      double lots = 0.0;
      
      // remidner: Bid = Current Candles on chart aka where I want the orders to be triggered at
      if (SetUpType == OP_BUY)
      {
         // buy at the ask: move order up to ensure that I get in when the bid touches the zone
         entryPrice = ZoneStates[i].EntryPrice() + OrderHelper::PipsToRange(MaxSpreadPips);
         stopLossRange = ZoneStates[i].Range() + OrderHelper::PipsToRange(MaxSpreadPips) + OrderHelper::PipsToRange(StopLossPaddingPips);
         
         // Stop loss is going to be at exit of zone + padding so that it can be hit when the bid reaches it
         stopLoss = entryPrice - stopLossRange;
         takeProfit = entryPrice + (stopLossRange * PartialOneRR);
      }
      else if (SetUpType == OP_SELL)
      {
         // sell at the bid: Don't move the order to ensure that I get in when the bid touches the zone
         entryPrice = ZoneStates[i].EntryPrice();
         stopLossRange = ZoneStates[i].Range() + OrderHelper::PipsToRange(MaxSpreadPips) + OrderHelper::PipsToRange(StopLossPaddingPips);
         
         // Stop loss is going to be at exit of zones + padding + spread so that it can be hit when the bid reaches it
         stopLoss = entryPrice + stopLossRange;
         takeProfit = entryPrice - (stopLossRange * PartialOneRR);
      }

      lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(stopLossRange), RiskPercent);
      
      OrderHelper::PlaceLimitOrderWithSinglePartial(orderType, lots, entryPrice, stopLoss, takeProfit, PartialOnePercent, MagicNumber);
      CanceledAllPendingOrders = false;
   }   
}

// remove all references to states so I can't rely on them later / theres no gurantee they'll still exist
// anything that relys on a states value in the future needs to be stored 
void ClearMBs()
{
   ArrayFree(MBSetUpStates);
   ArrayResize(MBSetUpStates, MBsNeeded);
}

void ClearZones()
{
   ArrayFree(ZoneStates);
   ArrayResize(ZoneStates, MaxZonesInMB);
}