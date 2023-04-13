//+------------------------------------------------------------------+
//|                                                     EAOrderPlaceHelper.mqh |
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

class EAOrderPlaceHelper
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
    static void PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error, double originalEntryPrice);

    // =========================================================================
    // Base Order Methods
    // =========================================================================

    template <typename TEA>
    static void InternalPlaceMarketOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lot, double takeProfit);
    template <typename TEA>
    static void InternalPlaceLimitOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lots, bool fallbackMarketOrder, double maxMarketOrderSlippage);
    template <typename TEA>
    static void InternalPlaceStopOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lots, bool fallbackMarketOrder, double maxMarketOrderSlippage);

public:
    template <typename TEA>
    static void PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lot, double takeProfit, OrderType orderTypeOverride);
    template <typename TEA>
    static void PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lots, bool fallbackMarketOrder, double maxMarketOrderSlippage, OrderType orderTypeOverride);
    template <typename TEA>
    static void PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lots, bool fallbackMarketOrder, double maxMarketOrderSlippage, OrderType orderTypeOverride);
    // =========================================================================
    // Setup Specific Order Methods
    // =========================================================================

    template <typename TEA>
    static void PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static void PlaceStopOrderForPendingLiquidationSetupValidation(TEA &ea, MBTracker *&mbt, int liquidationMBNumber);

    template <typename TEA>
    static void PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime);
    template <typename TEA>
    static void PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime);
    template <typename TEA>
    static void PlaceMarketOrderForMostRecentMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static void PlaceStopOrderForTheLittleDipper(TEA &ea);
};

/*

   _   _      _                   __  __      _   _               _
  | | | | ___| |_ __   ___ _ __  |  \/  | ___| |_| |__   ___   __| |___
  | |_| |/ _ \ | '_ \ / _ \ '__| | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  |  _  |  __/ | |_) |  __/ |    | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_| |_|\___|_| .__/ \___|_|    |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
               |_|

*/
double EAOrderPlaceHelper::GetLotSizeForRiskPercent(double stopLossPips, double riskPercent)
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

static void EAOrderPlaceHelper::CheckBreakLotSizeUp(double originalLotSize, int &numberOfOrders, double &lotSizeToUse)
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
static double EAOrderPlaceHelper::GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy)
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
static bool EAOrderPlaceHelper::PrePlaceOrderChecks(TEA &ea)
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
static void EAOrderPlaceHelper::PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error, double originalEntry)
{
    if (ticketNumber == EMPTY)
    {
        ea.InvalidateSetup(false, error);
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
static void EAOrderPlaceHelper::InternalPlaceMarketOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, double takeProfit)
{
    int ticket = EMPTY;
    int orderPlaceError = ea.mTM.PlaceMarketOrder(orderType, lotSize, entryPrice, stopLoss, takeProfit, ticket);

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, entryPrice);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, double takeProfit = 0.0,
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
static void EAOrderPlaceHelper::InternalPlaceLimitOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
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

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, entryPrice);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lots = 0.0, bool fallbackMarketOrder = false,
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

    if (lots == 0.0)
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
static void EAOrderPlaceHelper::InternalPlaceStopOrder(TEA &ea, OrderType orderType, double entryPrice, double stopLoss, double lots, bool fallbackMarketOrder,
                                                       double maxMarketOrderSlippage)
{
    int ticket = EMPTY;
    int orderPlaceError = ERR_NO_ERROR;

    if (orderType == OrderType::BuyStop)
    {
        if (fallbackMarketOrder && entryPrice <= ea.CurrentTick().Ask() && ea.CurrentTick().Ask() - entryPrice <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OrderType::Buy, lots, ea.CurrentTick().Ask(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(orderType, lots, entryPrice, stopLoss, 0, ticket);
        }
    }
    else if (orderType == OrderType::SellStop)
    {
        if (fallbackMarketOrder && entryPrice >= ea.CurrentTick().Bid() && entryPrice - ea.CurrentTick().Bid() <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(OP_SELL, lots, ea.CurrentTick().Bid(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(orderType, lots, entryPrice, stopLoss, 0, ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError, entryPrice);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lots = 0.0, bool fallbackMarketOrder = false,
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

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                            mbNumber, mbt, ticketNumber);
    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForBreakOfMB(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                  mbNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrderForPendingLiquidationSetupValidation(TEA &ea, MBTracker *&mbt, int liquidationMBNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingLiquidationSetupValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                                          liquidationMBNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime)
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
static void EAOrderPlaceHelper::PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int stopLossCandleIndex = iBarShift(symbol, timeFrame, stopLossCandleTime);

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrderForCandleSetup(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                      ea.SetupType(), symbol, timeFrame, stopLossCandleIndex, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceMarketOrderForMostRecentMB(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrderForMostRecentMB(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(), ea.SetupType(),
                                                                       mbNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAOrderPlaceHelper::PlaceStopOrderForTheLittleDipper(TEA &ea)
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