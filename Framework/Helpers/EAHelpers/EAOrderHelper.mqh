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
    static void PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error, OrderType orderType, double originalEntry, double stopLoss, double lotSize, double takeProfit);

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
    static void PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime);
    template <typename TEA>
    static void PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime);

    template <typename TEA>
    static void PlaceStopOrderForTheLittleDipper(TEA &ea);

    // =========================================================================
    // Managing Active Tickets
    // =========================================================================
    template <typename TEA>
    static void MoveTicketToBreakEven(TEA &ea, Ticket &ticket, double additionalPips);
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
static void EAOrderHelper::PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error, OrderType orderType, double originalEntry, double stopLoss, double lotSize,
                                                double takeProfit)
{
    if (ticketNumber == EMPTY)
    {
        string orderInfo =
            "Magic Number: " + IntegerToString(ea.MagicNumber()) +
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

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, takeProfit);
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

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
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

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
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

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, error, orderType, entryPrice, stopLoss, lotSize, 0);
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

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError, orderType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int entryCandleIndex = iBarShift(symbol, timeFrame, entryCandleTime);
    int stopLossCandleIndex = iBarShift(symbol, timeFrame, stopLossCandleTime);

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForCandleBreak(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                    ea.SetupType(), symbol, timeFrame, entryCandleIndex, stopLossCandleIndex, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderHelper::PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int stopLossCandleIndex = iBarShift(symbol, timeFrame, stopLossCandleTime);

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrderForCandleSetup(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                      ea.SetupType(), symbol, timeFrame, stopLossCandleIndex, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForTheLittleDipper(TEA &ea)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    if (ea.mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForTheLittleDipper(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                        ea.SetupType(), ea.mEntrySymbol, ea.mEntryTimeFrame, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

/*

   __  __                                   _        _   _             _____ _      _        _
  |  \/  | __ _ _ __   __ _  __ _  ___     / \   ___| |_(_)_   _____  |_   _(_) ___| | _____| |_ ___
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \   / _ \ / __| __| \ \ / / _ \   | | | |/ __| |/ / _ \ __/ __|
  | |  | | (_| | | | | (_| | (_| |  __/  / ___ \ (__| |_| |\ V /  __/   | | | | (__|   <  __/ |_\__ \
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___| /_/   \_\___|\__|_| \_/ \___|   |_| |_|\___|_|\_\___|\__|___/
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