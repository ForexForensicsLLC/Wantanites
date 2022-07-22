//+------------------------------------------------------------------+
//|                                                  SetUpHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

class SetupHelper
{
   private:
   
   public:
      // --- Range Broke Methods ---
      static bool BrokeMBRangeStart(int mbNumber, MBTracker* &mbt);
      static bool BrokeDoubleMBPlusLiquidationSetupRangeEnd(int secondMBInSetup, int setupType, MBTracker* &mbt);
      
      // --- MB Setup Methods ---
      static bool MostRecentMBPlusHoldingZone(int mostRecentMBNumber, MBTracker* &mbt);
      static bool FirstMBAfterLiquidationOfSecondPlusHoldingZone(int mbOneNumber, int mbTwoNumber, MBTracker* &mbt);
      
      // --- Min ROC. From Time Stamp Setup Methods ---
      static bool BreakAfterMinROC(MinROCFromTimeStamp* &mrfts, MBTracker* &mbt);
};

static bool SetupHelper::BrokeMBRangeStart(int mbNumber, MBTracker* &mbt)
{ 
   MBState* tempMBState;
   if (mbt.GetMB(mbNumber, tempMBState))
   {
      return tempMBState.IsBroken(tempMBState.EndIndex());
   }
   
   return false;
}

static bool SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(int secondMBInSetup, int setupType, MBTracker* &mbt)
{
   MBState* tempMBState;
   
   // Return false if we can't find the subsequent MB for whatever reason
   if (!mbt.GetMB(secondMBInSetup + 1, tempMBState))
   {
      return false;
   }
   
   // Types can't be equal if we are looking for a liquidation of the second MB
   if (tempMBState.Type() == setupType)
   {
      return false;
   }
   
   return tempMBState.IsBroken(tempMBState.EndIndex());
}

static bool SetupHelper::MostRecentMBPlusHoldingZone(int mostRecentMBNumber, MBTracker *&mbt)
{
   return mbt.MBIsMostRecent(mostRecentMBNumber) && mbt.MBsClosestValidZoneIsHolding(mostRecentMBNumber);
}

static bool SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(int mbOneNumber, int mbTwoNumber, MBTracker *&mbt)
{
   MBState* secondMBTempMBState;
   MBState* thirdMBTempState;
   
   if (mbt.GetMB(mbTwoNumber, secondMBTempMBState))
   {
      if (secondMBTempMBState.Type() == OP_BUY)
      {
         if (iLow(secondMBTempMBState.Symbol(), secondMBTempMBState.TimeFrame(), 0) < iLow(secondMBTempMBState.Symbol(), secondMBTempMBState.TimeFrame(), secondMBTempMBState.LowIndex()))
         {
            if (mbt.GetMB(mbTwoNumber + 1, thirdMBTempState))
            {
               return mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex());
            }
         }  
      }
      else if (secondMBTempMBState.Type() == OP_SELL)
      {
         if (iHigh(secondMBTempMBState.Symbol(), secondMBTempMBState.TimeFrame(), 0) > iHigh(secondMBTempMBState.Symbol(), secondMBTempMBState.TimeFrame(), secondMBTempMBState.HighIndex()))
         {
            if (mbt.GetMB(mbTwoNumber + 1, thirdMBTempState))
            {
               return mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex());
            }
         }
      }
   }
   
   return false;
}

// ---------------- Min ROC From Time Stamp Setup Methods
// Will check if there is a break of structure after a Min ROC From Time Stamp has occured
// The First Time this is true ensures that the msot recent mb is the first opposite one
static bool SetupHelper::BreakAfterMinROC(MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
{
   if (mrfts.Symbol() != mbt.Symbol() || mrfts.TimeFrame() != mbt.TimeFrame())
   {
      Print("Min ROC. From Time Stamp and MBTracker must have the same Symbol and Time Frame");
      return false;
   }
   
   if (mrfts.HadMinROC() && mbt.NthMostRecentMBIsOpposite(0))
   {
      MBState* tempMBStates[];   
      if (mbt.GetNMostRecentMBs(2, tempMBStates))
      {
         bool bothAbove = iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].LowIndex()) > mrfts.OpenPrice() && iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].LowIndex()) > mrfts.OpenPrice();
         bool bothBelow = iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].HighIndex()) < mrfts.OpenPrice() && iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].HighIndex()) < mrfts.OpenPrice();
         
         bool breakingUp = bothBelow && tempMBStates[0].Type() == OP_BUY;
         bool breakingDown = bothAbove && tempMBStates[0].Type() == OP_SELL;
         
         return breakingUp || breakingDown;
      }
   }
   
   return false;
}
