//+------------------------------------------------------------------+
//|                                                     EAOrderHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Types\OrderTypes.mqh>
#include <Wantanites\Framework\Types\SignalTypes.mqh>
#include <Wantanites\Framework\Utilities\PipConverter.mqh>

class EAOrderHelper
{
    // =========================================================================
    // Helper Methdos
    // =========================================================================

    static double GetLotSizeForRiskPercent(double stopLossPips, double riskPercent);
    static void CheckBreakLotSizeUp(double originalLotSize, int &numberOfOrders, double &lotSizeToUse);

    template <typename TEA>
    static double GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy);
    template <typename TEA>
    static bool PrePlaceOrderChecks(TEA &ea);
    template <typename TEA>
    static void PostPlaceOrderChecks(TEA &ea, string methodName, int ticketNumber, int error, OrderType orderType, double originalEntry, double stopLoss, double lotSize,
                                     double takeProfit);

    // =========================================================================
    // Base Order Methods
    // =========================================================================

    template <typename TEA>
    static void InternalPlaceMarketOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, double takeProfit);
    template <typename TEA>
    static void InternalPlaceLimitOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                        double maxMarketOrderSlippage);
    template <typename TEA>
    static void InternalPlaceStopOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                       double maxMarketOrderSlippage);

public:
    template <typename TEA>
    static void PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, double takeProfit, OrderType orderTypeOverride);
    template <typename TEA>
    static void PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder, double maxMarketOrderSlippage,
                                OrderType orderTypeOverride);
    template <typename TEA>
    static void PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder, double maxMarketOrderSlippage,
                               OrderType orderTypeOverride);
    // =========================================================================
    // Setup Specific Order Methods
    // =========================================================================
private:
    static int GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, int setupType, MBTracker *&mbt, double &entryPrice);
    static int GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, double &stopLoss);
    static int GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, double &entryPrice);
    static int GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, double &stopLoss);

public:
    template <typename TEA>
    static void PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, double lotSize);
    template <typename TEA>
    static void PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber, double lotSize);
    template <typename TEA>
    static void PlaceStopOrderForCandelBreak(TEA &ea, int entryCandleIndex, int stopLossCandleIndex, double takeProfit,
                                             OrderType orderType, double lotSize);

    // =========================================================================
    // Moving to Break Even
    // =========================================================================
    template <typename TEA>
    static void MoveTicketToBreakEven(TEA &ea, Ticket &ticket, double additionalPips);
    template <typename TEA>
    static void MoveTicketToBreakEvenWhenCandleClosesPastEntry(TEA &ea, Ticket &ticket);

    // =========================================================================
    // Editing Stop Losses
    // =========================================================================
    template <typename TEA>
    static void ModifyTicketStopLoss(TEA &ea, Ticket &ticket, string methodName, double newStopLoss, bool deleteOldOrder);
    template <typename TEA>
    static void CheckEditStopLossForCandleBreakStopOrder(TEA &ea, Ticket &ticket, bool deleteOldOrder);
    template <typename TEA>
    static void CheckEditStopLossForPendingMBStopOrder(TEA &ea, Ticket &ticket, MBTracker *&mbt, int mbNumber, bool placeNewOrder);
    template <typename TEA>
    static void CheckEditStopLossForBreakOfMBStopOrder(TEA &ea, Ticket &ticket, MBTracker *&mbt, int mbNumber, bool placeNewOrder);
    template <typename TEA>
    static void CheckTrailStopLossWithMBs(TEA &ea, Ticket &ticket, MBTracker *&mbt, bool stopAtBreakEven);

    // =========================================================================
    // Manage All Tickets
    // =========================================================================
    template <typename TEA>
    static void CloseAllPendingTickets(TEA &ea);
    template <typename TEA>
    static void CloseAllCurrentAndPreviousSetupTickets(TEA &ea);
};

/*

   _   _      _                   __  __      _   _               _
  | | | | ___| |_ __   ___ _ __  |  \/  | ___| |_| |__   ___   __| |___
  | |_| |/ _ \ | '_ \ / _ \ '__| | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  |  _  |  __/ | |_) |  __/ |    | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_| |_|\___|_| .__/ \___|_|    |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
               |_|

*/
double EAOrderHelper::GetLotSizeForRiskPercent(double stopLossPips, double riskPercent)
{
    double pipValue = MarketInfo(Symbol(), MODE_TICKSIZE) * 10 * MarketInfo(Symbol(), MODE_LOTSIZE);

    // since UJ starts with USD, it also involves the current price
    // TODO: update this to catch any other pairs
    if (StringFind(Symbol(), "JPY") != -1)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            Print("Can't get tick during lot size calculation");
            return 0.1;
        }

        pipValue = pipValue / currentTick.bid;
    }

    double lotSize = NormalizeDouble((AccountBalance() * riskPercent / 100) / (stopLossPips * pipValue), 2);
    return MathMax(MarketInfo(Symbol(), MODE_MINLOT), lotSize);
}

static void EAOrderHelper::CheckBreakLotSizeUp(double originalLotSize, int &numberOfOrders, double &lotSizeToUse)
{
    numberOfOrders = 1;
    lotSizeToUse = originalLotSize;

    while (lotSizeToUse > MarketInfo(Symbol(), MODE_MAXLOT))
    {
        numberOfOrders += 1;
        lotSizeToUse = originalLotSize / numberOfOrders;
    }
}

template <typename TEA>
static double EAOrderHelper::GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy)
{
    double calculatedRiskPercent = ea.mRiskPercent;
    double totalPercentLost = MathAbs((AccountBalance() - ea.mLargestAccountBalance) / ea.mLargestAccountBalance * 100);

    while (totalPercentLost >= perPercentLost)
    {
        calculatedRiskPercent -= reduceBy;
        totalPercentLost -= perPercentLost;
    }

    return calculatedRiskPercent;
}

template <typename TEA>
static bool EAOrderHelper::PrePlaceOrderChecks(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_TO_PLACE_ORDER;

    if (ea.mCurrentSetupTicket.Number() != EMPTY)
    {
        return false;
    }

    ea.mLastState = EAStates::COUNTING_OTHER_EA_ORDERS;

    int orders = 0;
    int ordersError = OrderHelper::CountOtherEAOrders(true, ea.mStrategyMagicNumbers, orders);
    if (ordersError != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(false, ordersError);
        return false;
    }

    if (orders >= ea.mMaxCurrentSetupTradesAtOnce)
    {
        ea.InvalidateSetup(false);
        return false;
    }

    return true;
}

template <typename TEA>
static void EAOrderHelper::PostPlaceOrderChecks(TEA &ea, string methodName, int ticketNumber, int error, OrderType orderType, double originalEntry, double stopLoss,
                                                double lotSize, double takeProfit)
{
    if (ticketNumber == EMPTY)
    {
        string orderInfo =
            "Method: " + methodName +
            " Magic Number: " + IntegerToString(ea.MagicNumber()) +
            " Type: " + IntegerToString(orderType) +
            " Ask: " + DoubleToString(ea.CurrentTick().Ask()) +
            " Bid: " + DoubleToString(ea.CurrentTick().Bid()) +
            " Entry: " + DoubleToString(originalEntry) +
            " Stop Loss: " + DoubleToString(stopLoss) +
            " Lot Size: " + DoubleToString(lotSize) +
            " Take Profit: " + DoubleToString(takeProfit);

        ea.RecordError(__FUNCTION__, error, orderInfo);
        return;
    }

    Ticket *ticket = new Ticket(ticketNumber);
    ticket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);
    ticket.OriginalOpenPrice(originalEntry);

    ea.mCurrentSetupTickets.Add(ticket);
}

/*

   ____                    ___          _             __  __      _   _               _
  | __ )  __ _ ___  ___   / _ \ _ __ __| | ___ _ __  |  \/  | ___| |_| |__   ___   __| |___
  |  _ \ / _` / __|/ _ \ | | | | '__/ _` |/ _ \ '__| | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  | |_) | (_| \__ \  __/ | |_| | | | (_| |  __/ |    | |  | |  __/ |_| | | | (_) | (_| \__ \
  |____/ \__,_|___/\___|  \___/|_|  \__,_|\___|_|    |_|  |_|\___|\__|_| |_|\___/ \__,_|___/


*/

template <typename TEA>
static void EAOrderHelper::InternalPlaceMarketOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, double takeProfit)
{
    int ticket = EMPTY;
    int orderPlaceError = ea.mTM.PlaceMarketOrder(orderType, lotSize, entryPrice, stopLoss, takeProfit, ticket);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, takeProfit);
}

template <typename TEA>
static void EAOrderHelper::PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, double takeProfit = 0.0,
                                            OrderType orderTypeOverride = OrderType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    OrderType orderType = orderTypeOverride;
    if (orderType == OrderType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            orderType = OrderType::Buy;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            orderType = OrderType::Sell;
        }
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(lotSize, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceMarketOrder(ea, orderType, entryPrice, stopLoss, lotsToUse, takeProfit);
    }
}

template <typename TEA>
static void EAOrderHelper::InternalPlaceLimitOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                                   double maxMarketOrderSlippage)
{
    int ticket = EMPTY;
    int orderPlaceError = ERR_NO_ERROR;

    if (orderType == OrderType::BuyLimit)
    {
        if (fallbackMarketOrder && entryPrice >= ea.CurrentTick().Ask() && ea.CurrentTick().Ask() - entryPrice <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OrderType::Buy, lotSize, ea.CurrentTick().Ask(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceLimitOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }
    else if (orderType == OrderType::SellLimit)
    {
        if (fallbackMarketOrder && entryPrice <= ea.CurrentTick().Bid() && entryPrice - ea.CurrentTick().Bid() <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OrderType::Buy, lotSize, ea.CurrentTick().Bid(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceLimitOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, bool fallbackMarketOrder = false,
                                           double maxMarketOrderSlippage = 0.0, OrderType orderTypeOverride = OrderType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    OrderType limitType = orderTypeOverride;
    if (limitType == OrderType::Empty)
    {
        if (ea.SetupType() == OrderType::Bullish)
        {
            limitType = OrderType::BuyLimit;
        }
        else if (ea.SetupType() == OrderType::Bearish)
        {
            limitType = OrderType::SellLimit;
        }
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(lots, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceLimitOrder(ea, limitType, entryPrice, stopLoss, lotsToUse, fallbackMarketOrder, maxMarketOrderSlippage);
    }
}

template <typename TEA>
static void EAOrderHelper::InternalPlaceStopOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                                  double maxMarketOrderSlippage)
{
    int ticket = EMPTY;
    int orderPlaceError = ERR_NO_ERROR;

    if (orderType == OrderType::BuyStop)
    {
        if (fallbackMarketOrder && entryPrice <= ea.CurrentTick().Ask() && ea.CurrentTick().Ask() - entryPrice <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OrderType::Buy, lotSize, ea.CurrentTick().Ask(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }
    else if (orderType == OrderType::SellStop)
    {
        if (fallbackMarketOrder && entryPrice >= ea.CurrentTick().Bid() && entryPrice - ea.CurrentTick().Bid() <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OP_SELL, lotSize, ea.CurrentTick().Bid(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lots = 0.0, bool fallbackMarketOrder = false,
                                          double maxMarketOrderSlippage = 0.0, OrderType orderTypeOverride = OrderType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    OrderType stopType = orderTypeOverride;
    if (stopType == OrderType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            stopType = OrderType::BuyStop;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            stopType = OrderType::SellStop;
        }
    }

    if (lots == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(lots, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceStopOrder(ea, stopType, entryPrice, stopLoss, lotsToUse, fallbackMarketOrder, maxMarketOrderSlippage);
    }
}

/*

   ____       _                 ____                  _  __ _         ___          _             __  __      _   _               _
  / ___|  ___| |_ _   _ _ __   / ___| _ __   ___  ___(_)/ _(_) ___   / _ \ _ __ __| | ___ _ __  |  \/  | ___| |_| |__   ___   __| |___
  \___ \ / _ \ __| | | | '_ \  \___ \| '_ \ / _ \/ __| | |_| |/ __| | | | | '__/ _` |/ _ \ '__| | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
   ___) |  __/ |_| |_| | |_) |  ___) | |_) |  __/ (__| |  _| | (__  | |_| | | | (_| |  __/ |    | |  | |  __/ |_| | | | (_) | (_| \__ \
  |____/ \___|\__|\__,_| .__/  |____/| .__/ \___|\___|_|_| |_|\___|  \___/|_|  \__,_|\___|_|    |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
                       |_|           |_|

*/
static int EAOrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, int setupType, MBTracker *&mbt, double &entryPrice)
{
    entryPrice = 0.0;
    int retracementIndex = EMPTY;

    if (setupType == OP_BUY)
    {
        // don't allow an order to be placed unless we have a pending mb and valid retracement
        if (!mbt.HasPendingBullishMB() || !mbt.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // only add spread to buys since we want to enter as the bid hits our entry
        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) + OrderHelper::PipsToRange(spreadPips);
    }
    else if (setupType == OP_SELL)
    {
        if (!mbt.HasPendingBearishMB() || !mbt.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // move the entry down 0.1 pips so that we only get entered if we actually validate the mb and if we just tap the range
        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) - PipsToRange(0.1);
    }

    return ERR_NO_ERROR;
}

static int EAOrderHelper::GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, double &stopLoss)
{
    stopLoss = 0.0;
    int retracementIndex = EMPTY;

    if (setupType == OP_BUY)
    {
        // don't allow an order to be placed unless we have a pending mb and valid retracement
        // TODO: move this check somewhere else
        if (!mbt.HasPendingBullishMB() || !mbt.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // subtract one so that we can't include the imbalance candle as the lowest
        double low = 0.0;
        if (!MQLHelper::GetLowestLowBetween(mbt.Symbol(), mbt.TimeFrame(), retracementIndex, 0, true, low))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
        }

        stopLoss = low - PipsToRange(paddingPips);
    }
    else if (setupType == OP_SELL)
    {
        if (!mbt.HasPendingBearishMB() || !mbt.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // subtract one so that we can't include the imbalance candle as the highest
        double high = 0.0;
        if (!MQLHelper::GetHighestHighBetween(mbt.Symbol(), mbt.TimeFrame(), retracementIndex, 0, true, high))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss = high + PipsToRange(paddingPips) + PipsToRange(spreadPips);
    }

    return ERR_NO_ERROR;
}

static int EAOrderHelper::GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, double &entryPrice)
{
    entryPrice = 0.0;

    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
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

static int EAOrderHelper::GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, double &stopLoss)
{
    stopLoss = 0.0;
    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        double high;
        if (!MQLHelper::GetHighestHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.EndIndex(), 0, true, high))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss = high + PipsToRange(paddingPips) + PipsToRange(spreadPips);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        double low = 0.0;
        if (!MQLHelper::GetLowestLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.EndIndex(), 0, true, low))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
        }

        stopLoss = low - PipsToRange(paddingPips);
    }

    return ERR_NO_ERROR;
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, double lotSize = 0.0)
{
    OrderType orderType = OrderType::Empty;
    if (ea.SetupType() == SignalType::Bullish)
    {
        orderType = OrderType::BuyStop;
    }
    else if (ea.SetupType() == SignalType::Bearish)
    {
        orderType = OrderType::SellStop;
    }

    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, mbt.GetNthMostRecentMBsType(0), mbt, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, mbt.GetNthMostRecentMBsType(0), mbt, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int ticketNumber = EMPTY;
    int error = ea.mTM.PlaceStopOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, error, orderType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber, double lotSize = 0.0)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderForBreakOfMB(spreadPips, mbNumber, mbt, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, mbNumber, mbt, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    OrderType orderType = OrderType::Empty;
    if (tempMBState.Type() == OP_BUY)
    {
        orderType = OrderType::SellStop;
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        orderType = OrderType::BuyStop;
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int ticketNumber = EMPTY;
    int orderPlaceError = ea.mTM.PlaceStopOrder(orderType, lotSize, entryPrice, stopLoss, 0, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForCandelBreak(TEA &ea, int entryCandleIndex, int stopLossCandleIndex, double takeProfit = 0.0,
                                                        OrderType orderType = OrderType::Empty, double lotSize = 0.0)
{
    double entryPrice;
    double stopLoss;

    OrderType type = orderType;
    if (type == OrderType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            type = OrderType::BuyStop;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            type = OrderType::SellStop;
        }
    }

    if (type == OrderType::BuyStop)
    {
        entryPrice = iHigh(symbol, timeFrame, entryCandleIndex);
        stopLoss = iLow(symbol, timeFrame, stopLossCandleIndex);
    }
    else if (type == OrderType::SellStop)
    {
        entryPrice = iLow(symbol, timeFrame, entryCandleIndex);
        stopLoss = iHigh(symbol, timeFrame, stopLossCandleIndex);
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForPercentRisk(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    }

    int ticketNumber = EMPTY;
    int orderPlaceError = ea.mTM.PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, takeProfit);
}
/*

   __  __            _               _____       ____                 _      _____
  |  \/  | _____   _(_)_ __   __ _  |_   _|__   | __ ) _ __ ___  __ _| | __ | ____|_   _____ _ __
  | |\/| |/ _ \ \ / / | '_ \ / _` |   | |/ _ \  |  _ \| '__/ _ \/ _` | |/ / |  _| \ \ / / _ \ '_ \
  | |  | | (_) \ V /| | | | | (_| |   | | (_) | | |_) | | |  __/ (_| |   <  | |___ \ V /  __/ | | |
  |_|  |_|\___/ \_/ |_|_| |_|\__, |   |_|\___/  |____/|_|  \___|\__,_|_|\_\ |_____| \_/ \___|_| |_|
                             |___/

*/
template <typename TEA>
static void EAOrderHelper::MoveTicketToBreakEven(TEA &ea, Ticket &ticket, double additionalPips = 0.0)
{
    if (ticket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool isActive = false;
    int isActiveError = ticket.IsActive(isActive);
    if (TerminalErrors::IsTerminalError(isActiveError))
    {
        ea.RecordError(__FUNCTION__, isActiveError);
        return;
    }

    if (!isActive)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN;

    bool stopLossIsMovedBreakEven;
    int stopLossIsMovedToBreakEvenError = ticket.StopLossIsMovedToBreakEven(stopLossIsMovedBreakEven);
    if (TerminalErrors::IsTerminalError(stopLossIsMovedToBreakEvenError))
    {
        ea.RecordError(__FUNCTION__, stopLossIsMovedToBreakEvenError);
        return;
    }

    if (stopLossIsMovedBreakEven)
    {
        return;
    }

    OrderType type = ticket.Type();
    if (type != OrderType::Buy && type != OrderType::Sell)
    {
        return;
    }

    ea.mLastState = EAStates::GETTING_CURRENT_TICK;

    double currentPrice;
    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        ea.RecordError(__FUNCTION__, GetLastError());
        return;
    }

    double additionalPrice = PipsConverter::PipsToPoints(additionalPips);
    double newPrice = 0.0;
    if (type == OrderType::Buy)
    {
        newPrice = ticket.OpenPrice() + additionalPrice;
        if (newPrice > currentTick.bid)
        {
            return;
        }
    }
    else if (type == OP_SELL)
    {
        newPrice = ticket.OpenPrice() - additionalPrice;
        if (newPrice < currentTick.ask)
        {
            return;
        }
    }

    ea.mLastState = EAStates::MODIFYING_ORDER;

    int error = ea.mTM.OrderModify(ticket.Number(), ticket.OpenPrice(), newPrice, ticket.TakeProfit(), ticket.ExpirationTime());
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, error);
    }
}

template <typename TEA>
void EAOrderHelper::MoveTicketToBreakEvenWhenCandleClosesPastEntry(TEA &ea, Ticket &ticket)
{
    OrderType ticketType = ticket.Type();
    bool furtherThanEntry = false;

    if (ticketType == OrderType::Buy)
    {
        furtherThanEntry = iLow(symbol, timeFrame, index) > ticket.OpenPrice();
    }
    else if (ticketType == OrderType::Sell)
    {
        furtherThanEntry = iHigh(symbol, timeFrame, index) < ticket.OpenPrice();
    }

    if (!furtherThanEntry)
    {
        return;
    }

    MoveTicketToBreakEven(ea, ticket, );
}

/*

   _____    _ _ _   _               ____  _                _
  | ____|__| (_) |_(_)_ __   __ _  / ___|| |_ ___  _ __   | |    ___  ___ ___  ___  ___
  |  _| / _` | | __| | '_ \ / _` | \___ \| __/ _ \| '_ \  | |   / _ \/ __/ __|/ _ \/ __|
  | |__| (_| | | |_| | | | | (_| |  ___) | || (_) | |_) | | |__| (_) \__ \__ \  __/\__ \
  |_____\__,_|_|\__|_|_| |_|\__, | |____/ \__\___/| .__/  |_____\___/|___/___/\___||___/
                            |___/                 |_|

*/
template <typename TEA>
void EAOrderHelper::ModifyTicketStopLoss(TEA &ea, Ticket &ticket, string methodName, double newStopLoss, bool deleteOldOrder)
{
    if (newStopLoss != ticket.CurrentStopLoss())
    {
        if (deleteOldOrder)
        {
            ticket.Close();

            double newTicketNumber = EMPTY;
            double lotSize = GetLotSizeForRiskPercent(PipConverter::PointsToPips(MathAbs(ticket.OpenPrice() - newStopLoss)), ea.RiskPercent());
            int error = ea.mTM.PlaceStopOrder(ticketType, ticket.EntryPrice(), newStopLoss, lotSize, ticket.TakeProfit(), newTicketNumber);
            PostPlaceOrderChecks<TEA>(ea, methodName, ticketNumber, error, ticketType, ticket.EntryPrice(), newStopLoss, lotSize, ticket.TakeProfit());
        }
        else
        {
            ea.mLastState = EAStates::MODIFYING_ORDER;

            int error = ea.mTM.ModifyOrder(ticket.Number(), ticket.OpenPrice(), newStopLoss, 0);
            if (error != Errors::NO_ERRORS)
            {
                ea.RecordError(__FUNCTION__, error, methodName);
            }
        }
    }
}
template <typename TEA>
void EAOrderHelper::CheckEditStopLossForCandleBreakStopOrder(TEA &ea, Ticket &ticket, bool deleteOldOrder)
{
    OrderType ticketType = ticket.Type();

    double newStopLoss = ticket.CurrentStopLoss();
    if (ticketType == OrderType::BuyStop)
    {
        double low = iLow(symbol, timeFrame, 0);
        if (low < newStopLoss)
        {
            newStopLoss = low - PipConverter::PipsToPoints(ea.StopLossPaddingPips());
        }
    }
    else if (ticketType == OrderType::SellStop)
    {
        double high = iHigh(symbol, timeFrame, 0);
        if (high > OrderStopLoss())
        {
            newStopLoss = high + PipConverter::PipsToPoints(ea.StopLossPaddingPips());
        }
    }
    else
    {
        return;
    }

    ModifyTicketStopLoss(ea, ticket, __FUNCTION__, newStopLoss, deleteOldOrder);
}

template <typename TEA>
void EAOrderHelper::CheckEditStopLossForPendingMBStopOrder(TEA &ea, Ticket &ticket, MBTracker *&mbt, int mbNumber, bool placeNewOrder)
{
    OrderType ticketType = ticket.Type();
    if (ticketType != OrderType::Buy && ticketType != OrderType::Sell)
    {
        return;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
        return;
    }

    double newStopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForPendingMBValidation(ea.StopLossPaddingPips(), 0.0, tempMBState.Type(), mbt, newStopLoss);
    if (stopLossError != Errors::NO_ERROR)
    {
        return stopLossError;
    }

    ModifyTicketStopLoss(ea, ticket, __FUNCTION__, newStopLoss, deleteOldOrder);
}

template <typename TEA>
void EAOrderHelper::CheckEditStopLossForBreakOfMBStopOrder(TEA &ea, Ticket &ticket, MBTracker *&mbt, int mbNumber, bool placeNewOrder)
{
    OrderType ticketType = ticket.Type();
    if (ticketType != OrderType::Buy && ticketType != OrderType::Sell)
    {
        return;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
        return;
    }

    double newStopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForBreakOfMB(ea.StopLossPaddingPips(), 0.0, mbNumber, mbt, newStopLoss);
    if (stopLossError != Errors::NO_ERROR)
    {
        return stopLossError;
    }

    ModifyTicketStopLoss(ea, ticket, __FUNCTION__, newStopLoss, deleteOldOrder);
}

template <typename TEA>
void EAOrderHelper::CheckTrailStopLossWithMBs(TEA &ea, Ticket &ticket, MBTracker *&mbt, bool stopAtBreakEven = true)
{
    OrderType ticketType = ticket.Type();
    if (ticketType != OrderType::Buy && ticketType != OrderType::Sell)
    {
        return;
    }

    MBState *tempMBState;
    if (!mbt.GetNthMostRecentMB(0, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
    }

    // only trail with same type MBs
    if ((ticketType == OrderType::Buy && tempMBState.Type() != SignalType::Bullish) ||
        (ticketType == OrderType::Sell && tempMBState.Type() != SignalType::Bearish))
    {
        return;
    }

    double currentStopLoss = ticket.CurrentStopLoss();
    double newStopLoss = 0.0;

    if (tempMBState.Type() == SignalType::Bullish)
    {
        newStopLoss = MathMax(currentStopLoss, iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.LowIndex()) -
                                                   PipConverter::PipsToPoints(ea.StopLossPaddingPips()));

        if (stopAtBreakEven)
        {
            newStopLoss = MathMin(ticket.OpenPrice(), newStopLoss);
        }
    }
    else if (tempMBState.Type() == SignalType::Bearish)
    {
        newStopLoss = MathMin(currentStopLoss, iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.HighIndex()) +
                                                   PipConverter::PipsToPoints(ea.StopLossPaddingPips()));

        if (stopAtBreakEven)
        {
            newStopLoss = MathMax(ticket.OpenPrice(), newStopLoss);
        }
    }

    ModifyTicketStopLoss(ea, ticket, __FUNCTION__, newStopLoss, false);
}
/*

   __  __                                   _    _ _   _____ _      _        _
  |  \/  | __ _ _ __   __ _  __ _  ___     / \  | | | |_   _(_) ___| | _____| |_ ___
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \   / _ \ | | |   | | | |/ __| |/ / _ \ __/ __|
  | |  | | (_| | | | | (_| | (_| |  __/  / ___ \| | |   | | | | (__|   <  __/ |_\__ \
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___| /_/   \_\_|_|   |_| |_|\___|_|\_\___|\__|___/
                            |___/

*/
template <typename TEA>
static void EAOrderHelper::CloseAllPendingTickets(TEA &ea)
{
    for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
    {
        bool active = false;
        int error = ea.mCurrentSetupTickets[i].IsActive(active);
        if (TerminalErrors::IsTerminalError(error))
        {
            ea.RecordError(__FUNCTION__, error);
        }

        if (!active)
        {
            ea.mCurrentSetupTickets[i].Close();
        }
    }

    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
    {
        bool active = false;
        int error = ea.mPreviousSetupTickets[i].IsActive(active);
        if (TerminalErrors::IsTerminalError(error))
        {
            ea.RecordError(__FUNCTION__, error);
        }

        if (!active)
        {
            ea.mPreviousSetupTickets[i].Close();
        }
    }
}

template <typename TEA>
static void EAOrderHelper::CloseAllCurrentAndPreviousSetupTickets(TEA &ea)
{
    for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
    {
        ea.mCurrentSetupTickets[i].Close();
    }

    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
    {
        ea.mPreviousSetupTickets[i].Close();
    }
}