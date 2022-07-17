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
#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.5;

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
int const MagicNumber = 10003;
int const MaxOrdersPerDay = 1;
int const MaxSpreadPips = 7; 

// --- EA Globals ---
MBTracker* MBT;
MBState* MBSetUpStates[];
ZoneState* ZoneStates[];

datetime MinROCTime = NULL;

double SetUpRangeStart = -1.0;
int SetUpType = -1;

bool SingleMBSetUp = false;
bool DoubleMBSetUp = false;

int MBOneNumber = -1;
int MBTwoNumber = -1;

bool StopTrading = false;
bool CanceledAllPendingOrders = false;

int OnInit()
{
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
   
   double openPrice = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
      
   Manage();
   CheckInvalidateSetup(openPrice);  
   CheckPlaceOrders();
   
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) / 10;
   
   if (openPrice != NULL)
   {
      if (currentSpread <= MaxSpreadPips)
      {    
         CheckSetSetup(openPrice);
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

void Manage()
{
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
                
         // Stop trading for the day
         if (tripleMB)
         {
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            CanceledAllPendingOrders = true;
            StopTrading = true;
         }
      }
   }
}

void CheckInvalidateSetup(double openPrice)
{
   if (SingleMBSetUp || DoubleMBSetUp)
   {
      bool brokeStartRange = (SetUpType == OP_BUY && Close[0] < SetUpRangeStart) || (SetUpType == OP_SELL && Close[0] > SetUpRangeStart);
      bool crossedOpenPrice = (Close[1] < openPrice && MathMax(Close[0], High[0]) > openPrice) || (Close[1] > openPrice && MathMin(Close[0], Low[0]) < openPrice);
      
      if (MinROCTime != NULL && (crossedOpenPrice || brokeStartRange))
      {                           
         OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
         StopTrading = true;
      }
   }
}

void CheckPlaceOrders()
{
   if (!StopTrading)
   {
      if (SingleMBSetUp || DoubleMBSetUp)
      {
         if (MBT.MBsClosestValidZoneIsHolding(MBOneNumber) || (MBTwoNumber > 0 && MBT.MBsClosestValidZoneIsHolding(MBTwoNumber)))
         {      
            if (OrdersTotal() == 0 && OrdersTotal() < MaxOrdersPerDay)
            {
               PlaceEditOrders(false);
            }
            else if (OrdersTotal() > 0)
            {
               PlaceOrders(true);
            }
         }
         else if (OrdersTotal() > 0)
         {
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
         }
      }      
   }
}

void PlaceOrders(bool cancelPrevious)
{
   int retracementIndex;
   double lots; 
   
   if (SetUpType == OP_BUY)
   {
      retracementIndex = MBT.CurrentBullishRetracementIndex();
      if (retracementIndex != -1)
      {  
         double entryPrice = iHigh(Symbol(), Period(), retracementIndex) + OrderHelper::PipsToRange(MaxSpreadPips);;
         double stopLoss = iLowest(Symbol(), Period(), MODE_LOW, retracementIndex, 0);
         
         lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(MathAbs(entryPrice - stopLoss)), RiskPercent);
         
         if (cancelPrevious)
         {
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
         }

          OrderHelper::PlaceStopOrder(OP_BUYSTOP, lots, entryPrice, stopLoss, 0, MagicNumber);         
      }
   }
   else if (SetUpType == OP_SELL)
   {
      retracementIndex = MBT.CurrentBearishRetracementIndex();
      if (retracementIndex != -1)
      {
         double entryPrice = iLow(Symbol(), Period(), retracementIndex);
         double stopLoss = iHighest(Symbol(), Period(), MODE_HIGH, retracementIndex, 0) + OrderHelper::PipsToRange(MaxSpreadPips);
         
         lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(MathAbs(entryPrice - stopLoss)), RiskPercent);
         
         if (cancelPrevious)
         {
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
         }

         OrderHelper::PlaceStopOrder(OP_BUYSTOP, lots, entryPrice, stopLoss, 0, MagicNumber);        
      }
   }
}

void CheckSetSetup(double openPrice)
{
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
               }
            }
         }
         
         ClearMBs();
      }   

      if (MinROCTime != NULL && SingleMBSetUp && !DoubleMBSetUp && MBT.HasNMostRecentConsecutiveMBs(2, MBSetUpStates))
      {
         Print("Double MB Setup");
         DoubleMBSetUp = true;             
         
         MBTwoNumber = MBSetUpStates[0].Number();              
         ClearMBs();
      }
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