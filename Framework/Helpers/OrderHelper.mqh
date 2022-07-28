//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Constants\Errors.mqh>

// HasUntestedMethods
class OrderHelper
{
protected:
    // ==========================================================================
    // Error Handling
    // ==========================================================================
    // !Tested
    static void SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber, int error);

public:
    // ==========================================================================
    // Calculating Orders
    // ==========================================================================
    // Tested
    static double RangeToPips(double range);

    // Tested
    static double PipsToRange(double pips);

    // !Tested
    static double GetLotSize(double stopLossPips, double riskPercent);

    // Tested
    // ResetsOutParam
    static int GetEntryPriceForStopOrderOnMostRecentPendingMB(double spreadPips, int setupType, MBTracker *&mbt, out double &entryPrice);

    // !Tested
    // ResetsOutParam
    static int GetStopLossForStopOrderOnMostRecentPendingMB(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, out double &stopLoss);

    // !TestedS
    // ResetsOutParam
    static int GetEntryPriceForStopOrderOnBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, out double &entryPrice);

    // !Tested
    // ResetsOutParam
    static int GetStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, out double &stopLoss);

    // ==========================================================================
    // Selecting Orders
    // ==========================================================================
    // !Tested
    static int SelectOpenOrderByPosition(int position, string action);

    // !Tested
    static int SelectOpenOrderByTicket(int ticket, string action);

    // !Tested
    static int SelectClosedOrderByTicket(int ticket, string action);

    // ==========================================================================
    // Checking Orders
    // ==========================================================================
    // Tested
    // ResetsOutParam
    static int IsPendingOrder(int ticket, out bool &isTrue);

    // Tested
    // ResetsOutParam
    static int CountOtherEAOrders(int &magicNumbers[], out int &orders);

    // ==========================================================================
    // Placing Limit Orders
    // ==========================================================================
    // !Tested
    // static bool PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber);

    // ==========================================================================
    // Placing Stop Orders
    // ==========================================================================
    // !Tested
    // ResetsOutParam
    static int PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber, out int &ticket);

    // ==========================================================================
    // Placing Stop Orders on MBs
    // ==========================================================================
    // !Tested
    // ResetsOutParam
    static int PlaceStopOrderOnMostRecentPendingMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int setupMBNumber, MBTracker *&mbt, out int &ticket);

    // !Tested
    // ResetsOutParam
    static int PlaceStopOrderOnBreakOfMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker *&mbt, out int &ticket);

    // ==========================================================================
    // Editing Orders
    // ==========================================================================
    // !Tested
    // static bool EditStopLoss(double newStopLoss, double newLots, int magicNumber);

    // ==========================================================================
    // Editing Orders For MB Stop Orders
    // ==========================================================================
    // !Tested
    static int CheckEditStopLossForStopOrderOnPendingMB(double paddingPips, double spreadPips, double riskPercent, int setupMBNumber, MBTracker *&mbt, out int &ticket);

    // ==========================================================================
    // Canceling Pending Orders
    // ==========================================================================
    // !Tested
    // static bool CancelAllPendingOrdersByMagicNumber(int magicNumber);

    // Tested
    static int CancelPendingOrderByTicket(out int &ticket);

    // ==========================================================================
    // Moving To Break Even
    // ==========================================================================
    // !Tested
    // static bool MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber);

    // ==========================================================================
    // Moving To Break Even By MB
    // ==========================================================================
    // !Tested
    // static bool TrailAllOrdersToMBUpToBreakEven(int magicNumber, double paddingPips, double spreadPips, MBState *&mbState);

    // !Tested
    static int CheckTrailStopLossWithMBUpToBreakEven(int ticket, double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker *&mbt, out bool &succeeded);
};
/*

   _____                       _   _                 _ _ _
  | ____|_ __ _ __ ___  _ __  | | | | __ _ _ __   __| | (_)_ __   __ _
  |  _| | '__| '__/ _ \| '__| | |_| |/ _` | '_ \ / _` | | | '_ \ / _` |
  | |___| |  | | | (_) | |    |  _  | (_| | | | | (_| | | | | | | (_| |
  |_____|_|  |_|  \___/|_|    |_| |_|\__,_|_| |_|\__,_|_|_|_| |_|\__, |
                                                                 |___/

*/
static void OrderHelper::SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber, int error)
{
    SendMail("Failed to place order",
             "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
                 "Magic Number: " + IntegerToString(magicNumber) + "\n" +
                 "Order Number: " + IntegerToString(orderNumber) + "\n" +
                 "Type: " + IntegerToString(orderType) + "\n" +
                 "Ask: " + DoubleToString(Ask) + "\n" +
                 "Bid: " + DoubleToString(Bid) + "\n" +
                 "Entry: " + DoubleToString(entryPrice) + "\n" +
                 "Stop Loss: " + DoubleToString(stopLoss) + "\n" +
                 // "Stop Loss Pips: " + DoubleToString(stopLossPips) + "\n" +
                 "Lots: " + DoubleToString(lots) + "\n" +
                 "Error: " + IntegerToString(error));
}
/*

    ____      _            _       _   _                ___          _
   / ___|__ _| | ___ _   _| | __ _| |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  | |   / _` | |/ __| | | | |/ _` | __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | (__| |_| | | (_| | |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
   \____\__,_|_|\___|\__,_|_|\__,_|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                                               |___/

*/
static double OrderHelper::RangeToPips(double range)
{
    // do Digits - 1 for pips otherwise it would be in pippetts
    return range * MathPow(10, Digits - 1);
}
static double OrderHelper::PipsToRange(double pips)
{
    // do Digits - 1 for pips otherwise it would be in pippetts
    return pips / MathPow(10, Digits - 1);
}
static double OrderHelper::GetLotSize(double stopLossPips, double riskPercent)
{
    double LotSize = (AccountBalance() * riskPercent / 100) / stopLossPips / MarketInfo(Symbol(), MODE_LOTSIZE);
    return MathMax(LotSize, MarketInfo(Symbol(), MODE_MINLOT));
}
static int OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(double spreadPips, int setupType, MBTracker *&mbt, out double &entryPrice)
{
    entryPrice = 0.0;

    if (setupType == OP_BUY)
    {
        int retracementIndex = mbt.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return Errors::ERR_EMPTY_BULLISH_RETRACEMENT;
        }

        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) + OrderHelper::PipsToRange(spreadPips);
    }
    else if (setupType == OP_SELL)
    {
        int retracementIndex = mbt.CurrentBearishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return Errors::ERR_EMPTY_BEARISH_RETRACEMENT;
        }

        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), retracementIndex);
    }

    return ERR_NO_ERROR;
}
static int OrderHelper::GetStopLossForStopOrderOnMostRecentPendingMB(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, out double &stopLoss)
{
    stopLoss = 0.0;

    if (setupType == OP_BUY)
    {
        int retracementIndex = mbt.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return Errors::ERR_EMPTY_BULLISH_RETRACEMENT;
        }

        stopLoss = iLow(mbt.Symbol(), mbt.TimeFrame(), iLowest(mbt.Symbol(), mbt.TimeFrame(), MODE_LOW, retracementIndex, 0)) + PipsToRange(paddingPips);
    }
    else if (setupType == OP_SELL)
    {
        int retracementIndex = mbt.CurrentBearishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return Errors::ERR_EMPTY_BEARISH_RETRACEMENT;
        }

        stopLoss = iHigh(mbt.Symbol(), mbt.TimeFrame(), iHighest(mbt.Symbol(), mbt.TimeFrame(), MODE_HIGH, retracementIndex, 0)) + PipsToRange(paddingPips) + PipsToRange(spreadPips);
    }

    return ERR_NO_ERROR;
}
static int OrderHelper::GetEntryPriceForStopOrderOnBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, out double &entryPrice)
{
    entryPrice = 0.0;

    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex());
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex()) + PipsToRange(spreadPips);
    }

    return ERR_NO_ERROR;
}
static int OrderHelper::GetStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, out double &stopLoss)
{
    stopLoss = 0.0;
    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        stopLoss = iHigh(mbt.Symbol(), mbt.TimeFrame(), iHighest(mbt.Symbol(), mbt.TimeFrame(), MODE_HIGH, tempMBState.EndIndex(), 0)) + PipsToRange(paddingPips) + PipsToRange(spreadPips);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        stopLoss = iLow(mbt.Symbol(), mbt.TimeFrame(), iLowest(mbt.Symbol(), mbt.TimeFrame(), MODE_LOW, tempMBState.EndIndex(), 0)) + PipsToRange(paddingPips);
    }

    return ERR_NO_ERROR;
}
/*

   ____       _           _   _                ___          _
  / ___|  ___| | ___  ___| |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  \___ \ / _ \ |/ _ \/ __| __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
   ___) |  __/ |  __/ (__| |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
  |____/ \___|_|\___|\___|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                                      |___/

*/
static int OrderHelper::SelectOpenOrderByPosition(int position, string action)
{
    int error = ERR_NO_ERROR;
    if (!OrderSelect(position, SELECT_BY_POS, MODE_TRADES))
    {
        error = GetLastError();
        SendMail("Failed To Select Open Order By Position When " + action,
                 "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Order Index: " + IntegerToString(position) + "\n" +
                     IntegerToString(error));
    }

    return error;
}

static int OrderHelper::SelectOpenOrderByTicket(int ticket, string action)
{
    int error = ERR_NO_ERROR;

    if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
    {
        error = GetLastError();
        SendMail("Failed To Select Open Order By Ticket When " + action,
                 "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Ticket: " + IntegerToString(ticket) + "\n" +
                     IntegerToString(error));
    }

    return error;
}

static int OrderHelper::SelectClosedOrderByTicket(int ticket, string action)
{
    int error = ERR_NO_ERROR;

    if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY))
    {
        error = GetLastError();
        SendMail("Failed To Select Closed Order By Ticket When " + action,
                 "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Current Ticket: " + IntegerToString(ticket) + "\n" +
                     IntegerToString(error));
    }

    return error;
}

/*

    ____ _               _    _                ___          _
   / ___| |__   ___  ___| | _(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  | |   | '_ \ / _ \/ __| |/ / | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |___| | | |  __/ (__|   <| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
   \____|_| |_|\___|\___|_|\_\_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                                      |___/

*/
static int OrderHelper::IsPendingOrder(int ticket, out bool &isTrue)
{
    isTrue = false;
    int selectError = SelectOpenOrderByTicket(ticket, "Checking if Pending Order");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    // OP_BUY == 0, OP_SELL = 1, anything else is above
    isTrue = OrderType() > 1;
    return ERR_NO_ERROR;
}

static int OrderHelper::CountOtherEAOrders(int &magicNumbers[], out int &orders)
{
    orders = 0;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        int selectError = SelectOpenOrderByPosition(i, "Checking if other EAs placed orders");
        if (selectError != ERR_NO_ERROR)
        {
            return selectError;
        }

        for (int j = 0; j < ArraySize(magicNumbers) - 1; j++)
        {
            if (OrderMagicNumber() == magicNumbers[j])
            {
                orders += 1;
            }
        }
    }

    return ERR_NO_ERROR;
}
/*

   ____  _            _               _     _           _ _      ___          _
  |  _ \| | __ _  ___(_)_ __   __ _  | |   (_)_ __ ___ (_) |_   / _ \ _ __ __| | ___ _ __ ___
  | |_) | |/ _` |/ __| | '_ \ / _` | | |   | | '_ ` _ \| | __| | | | | '__/ _` |/ _ \ '__/ __|
  |  __/| | (_| | (__| | | | | (_| | | |___| | | | | | | | |_  | |_| | | | (_| |  __/ |  \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |_____|_|_| |_| |_|_|\__|  \___/|_|  \__,_|\___|_|  |___/
                              |___/

*/
/*
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
*/
/*

   ____  _            _               ____  _                 ___          _
  |  _ \| | __ _  ___(_)_ __   __ _  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___
  | |_) | |/ _` |/ __| | '_ \ / _` | \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|
  |  __/| | (_| | (__| | | | | (_| |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/
                              |___/                 |_|

*/
static int OrderHelper::PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber, out int &ticket)
{
    ticket = EMPTY;

    if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP)
    {
        return Errors::ERR_WRONG_ORDER_TYPE;
    }

    if ((orderType == OP_BUYSTOP && stopLoss >= entryPrice) || (orderType == OP_SELLSTOP && stopLoss <= entryPrice))
    {
        return Errors::ERR_STOPLOSS_ABOVE_ENTRY;
    }

    int error = ERR_NO_ERROR;

    ticket = OrderSend(NULL, orderType, lots, entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);
    if (ticket < 0)
    {
        error = GetLastError();
        SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber, error);
    }

    return error;
}
/*

   ____  _            _               ____  _                 ___          _                               __  __ ____
  |  _ \| | __ _  ___(_)_ __   __ _  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___    ___  _ __   |  \/  | __ ) ___
  | |_) | |/ _` |/ __| | '_ \ / _` | \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|  / _ \| '_ \  | |\/| |  _ \/ __|
  |  __/| | (_| | (__| | | | | (_| |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \ | (_) | | | | | |  | | |_) \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/  \___/|_| |_| |_|  |_|____/|___/
                              |___/                 |_|

*/
int OrderHelper::PlaceStopOrderOnMostRecentPendingMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int setupMBNumber, MBTracker *&mbt, out int &ticket)
{
    ticket = EMPTY;

    MBState *tempMBState;
    if (!mbt.MBIsMostRecent(setupMBNumber, tempMBState))
    {
        return Errors::ERR_MB_IS_NOT_MOST_RECENT;
    }

    int type = tempMBState.Type() + 4;
    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, tempMBState.Type(), mbt, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, tempMBState.Type(), mbt, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);

    return PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber, ticket);
}

int OrderHelper::PlaceStopOrderOnBreakOfMB(int paddingPips, int spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker *&mbt, out int &ticket)
{
    ticket = EMPTY;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::ERR_MB_IS_NOT_MOST_RECENT;
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

    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderOnBreakOfMB(spreadPips, mbNumber, mbt, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderOnBreakOfMB(paddingPips, spreadPips, mbNumber, mbt, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);

    return PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber, ticket);
}
/*

   _____    _ _ _   _                ___          _
  | ____|__| (_) |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  |  _| / _` | | __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
  |_____\__,_|_|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                            |___/

*/
/*
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
*/
/*

   _____    _ _ _   _                ___          _                 _____            __  __ ____    ____  _                 ___          _
  | ____|__| (_) |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___  |  ___|__  _ __  |  \/  | __ )  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___
  |  _| / _` | | __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __| | |_ / _ \| '__| | |\/| |  _ \  \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \ |  _| (_) | |    | |  | | |_) |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \
  |_____\__,_|_|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/ |_|  \___/|_|    |_|  |_|____/  |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/
                            |___/                                                                                 |_|

*/
static int OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(double paddingPips, double spreadPips, double riskPercent, int setupMBNumber, MBTracker *&mbt, out int &ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(setupMBNumber, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    double newStopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, tempMBState.Type(), mbt, newStopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    bool selectError = SelectOpenOrderByTicket(ticket, "Editing Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        ticket = EMPTY;
        return selectError;
    }

    if (OrderStopLoss() == newStopLoss)
    {
        return Errors::ERR_NEW_STOPLOSS_EQUALS_OLD;
    }

    int type = OrderType();
    double entryPrice = OrderOpenPrice();
    double takeProfit = OrderTakeProfit();
    string comment = OrderComment();
    int magicNumber = OrderMagicNumber();
    datetime expiration = OrderExpiration();

    int cancelError = CancelPendingOrderByTicket(ticket);
    if (cancelError != ERR_NO_ERROR)
    {
        return cancelError;
    }

    double newLots = GetLotSize(RangeToPips(MathAbs(entryPrice - newStopLoss)), riskPercent);
    int error = ERR_NO_ERROR;
    int newTicket = OrderSend(Symbol(), type, newLots, OrderOpenPrice(), 0, newStopLoss, takeProfit, comment, magicNumber, expiration, clrNONE);
    if (newTicket < 0)
    {
        error = GetLastError();
        SendFailedOrderEMail(1, type, entryPrice, newStopLoss, newLots, magicNumber, error);

        return error;
    }

    ticket = newTicket;
    return error;
}
/*

    ____                     _ _               ____                _ _                ___          _
   / ___|__ _ _ __   ___ ___| (_)_ __   __ _  |  _ \ ___ _ __   __| (_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  | |   / _` | '_ \ / __/ _ \ | | '_ \ / _` | | |_) / _ \ '_ \ / _` | | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | | | (_|  __/ | | | | | (_| | |  __/  __/ | | | (_| | | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
   \____\__,_|_| |_|\___\___|_|_|_| |_|\__, | |_|   \___|_| |_|\__,_|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                                       |___/                                 |___/

*/
/*
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
*/
static int OrderHelper::CancelPendingOrderByTicket(out int &ticket)
{
    int error = ERR_NO_ERROR;

    if (!OrderDelete(ticket))
    {
        error = GetLastError();
        SendMail("Failed To Delete Order",
                 "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                     "Ticket: " + IntegerToString(ticket) + "\n" +
                     IntegerToString(error));

        return error;
    }

    ticket = EMPTY;
    return ERR_NO_ERROR;
}
/*

   __  __            _               _____       ____                 _      _____
  |  \/  | _____   _(_)_ __   __ _  |_   _|__   | __ ) _ __ ___  __ _| | __ | ____|_   _____ _ __
  | |\/| |/ _ \ \ / / | '_ \ / _` |   | |/ _ \  |  _ \| '__/ _ \/ _` | |/ / |  _| \ \ / / _ \ '_ \
  | |  | | (_) \ V /| | | | | (_| |   | | (_) | | |_) | | |  __/ (_| |   <  | |___ \ V /  __/ | | |
  |_|  |_|\___/ \_/ |_|_| |_|\__, |   |_|\___/  |____/|_|  \___|\__,_|_|\_\ |_____| \_/ \___|_| |_|
                             |___/

*/
/*
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
      if (OrderType() < 2 && OrderMagicNumber() == magicNumber)
      {
         if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration(), clrNONE))
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
*/
/*

   __  __            _               _____       ____                 _      _____                   ____          __  __ ____
  |  \/  | _____   _(_)_ __   __ _  |_   _|__   | __ ) _ __ ___  __ _| | __ | ____|_   _____ _ __   | __ ) _   _  |  \/  | __ )
  | |\/| |/ _ \ \ / / | '_ \ / _` |   | |/ _ \  |  _ \| '__/ _ \/ _` | |/ / |  _| \ \ / / _ \ '_ \  |  _ \| | | | | |\/| |  _ \
  | |  | | (_) \ V /| | | | | (_| |   | | (_) | | |_) | | |  __/ (_| |   <  | |___ \ V /  __/ | | | | |_) | |_| | | |  | | |_) |
  |_|  |_|\___/ \_/ |_|_| |_|\__, |   |_|\___/  |____/|_|  \___|\__,_|_|\_\ |_____| \_/ \___|_| |_| |____/ \__, | |_|  |_|____/
                             |___/                                                                         |___/

*/
/*
static bool OrderHelper::TrailAllOrdersToMBUpToBreakEven(int magicNumber, double paddingPips, double spreadPips, MBState *&mbState)
{
   bool allOrdersMoved = true;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!SelectOrderByPosition(i, "Trailing to MB up to Break Even"))
      {
         allOrdersMoved = false;
      }

      // OP_BUY or OP_SELL
      if (OrderType() < 2 && OrderMagicNumber() == magicNumber)
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

         if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), OrderExpiration(), clrGreen))
         {
            SendMail("Failed to trail stop loss",
                     "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
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
static int OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(int ticket, double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker *&mbt, out bool &succeeded)
{
    succeeded = false;

    int selectError = SelectOpenOrderByTicket(ticket, "Trailing with MBs");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    if (OrderType() > 2)
    {
        return Errors::ERR_WRONG_ORDER_TYPE;
    }

    MBState *tempMBState;
    if (!mbt.GetNthMostRecentMB(0, tempMBState))
    {
        return Errors::ERR_MB_IS_NOT_MOST_RECENT;
    }

    if (tempMBState.Number() <= setUpMB)
    {
        return Errors::ERR_SUBSEQUENT_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != setUpType)
    {
        return Errors::ERR_NOT_EQUAL_MB_TYPES;
    }

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
        return Errors::ERR_NEW_STOPLOSS_EQUALS_OLD;
    }

    int error = ERR_NO_ERROR;
    if (!OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), OrderExpiration(), clrGreen))
    {
        error = GetLastError();
        SendMail("Failed to trail stop loss",
                 "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     "Type: " + IntegerToString(OrderType()) + "\n" +
                     "Ask: " + DoubleToString(Ask) + "\n" +
                     "Bid: " + DoubleToString(Bid) + "\n" +
                     "Entry: " + DoubleToString(OrderOpenPrice()) + "\n" +
                     "Current Stop Loss: " + DoubleToString(currentStopLoss) + "\n" +
                     "New Stop Loss: " + DoubleToString(newStopLoss) + "\n" +
                     "Error: " + IntegerToString(error));
    }

    succeeded = true;
    return error;
}
