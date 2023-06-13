//+------------------------------------------------------------------+
//|                                                     EAOrderHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Types\TicketTypes.mqh>
#include <Wantanites\Framework\Types\SignalTypes.mqh>
#include <Wantanites\Framework\Utilities\PipConverter.mqh>

class EAOrderHelper
{
    // =========================================================================
    // Helper Methdos
    // =========================================================================

    static bool LotSizeIsInvalid(string symbol, TicketType type, double lotSize);
    static double GetLotSizeForRiskPercent(string symbol, double stopLossPips, double riskPercent);
    static void CheckBreakLotSizeUp(string symbol, double originalLotSize, int &numberOfOrders, double &lotSizeToUse);

    template <typename TEA>
    static double GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy);
    template <typename TEA>
    static bool PrePlaceOrderChecks(TEA &ea);
    template <typename TEA>
    static void PostPlaceOrderChecks(TEA &ea, string methodName, int ticketNumber, int error, TicketType ticketType, double originalEntry, double stopLoss, double lotSize,
                                     double takeProfit, double accountBalanceBefore);

    // =========================================================================
    // Base Order Methods
    // =========================================================================

    template <typename TEA>
    static void InternalPlaceMarketOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, double takeProfit);
    template <typename TEA>
    static void InternalPlaceLimitOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                        double maxMarketOrderSlippage);
    template <typename TEA>
    static void InternalPlaceStopOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, double takeProfit, bool fallbackMarketOrder,
                                       double maxMarketOrderSlippage);

public:
    template <typename TEA>
    static void PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, double takeProfit, TicketType orderTypeOverride);
    template <typename TEA>
    static void PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder, double maxMarketOrderSlippage,
                                TicketType orderTypeOverride);
    template <typename TEA>
    static void PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize, double takeProfit, bool fallbackMarketOrder, double maxMarketOrderSlippage,
                               TicketType orderTypeOverride);
    // =========================================================================
    // Setup Specific Order Methods
    // =========================================================================
private:
    static int GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, SignalType setupType, MBTracker *&mbt, double &entryPrice);
    static int GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, SignalType setupType, MBTracker *&mbt, double &stopLoss);
    static int GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, double &entryPrice);
    static int GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, double &stopLoss);

public:
    template <typename TEA>
    static void PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, double lotSize);
    template <typename TEA>
    static void PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber, double lotSize);
    template <typename TEA>
    static void PlaceStopOrderForCandelBreak(TEA &ea, int entryCandleIndex, int stopLossCandleIndex, double takeProfit,
                                             TicketType ticketType, double lotSize);

    template <typename TEA>
    static void MimicOrders(TEA &ea);
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

    // =========================================================================
    // Manage Active Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckTrailStopLossEveryXPips(TEA &ea, Ticket &ticket, double xPips, double trailBehindPips);
    template <typename TEA>
    static void MoveToBreakEvenAfterPips(TEA &ea, Ticket &ticket, double pipsToWait, double additionalPips);
    template <typename TEA>
    static void MoveToBreakEvenWithCandleCloseFurtherThanEntry(TEA &ea, Ticket &ticket, double additionalPips);
    template <typename TEA>
    static void MoveToBreakEvenAfterNextSameTypeMBValidation(TEA &ea, Ticket &ticket, MBTracker *&mbt, int entryMB);
    template <typename TEA>
    static void CheckPartialTicket(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void CloseIfPriceCrossedTicketOpen(TEA &ea, Ticket &ticket, int candlesAfterOpen);
    template <typename TEA>
    static void MoveStopLossToCoverCommissions(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static bool CloseIfPercentIntoStopLoss(TEA &ea, Ticket &ticket, double percent);

    template <typename TEA>
    static bool CloseTicketIfPastTime(TEA &ea, Ticket &ticket, int hour, int minute, bool fallbackCloseAtNewDay);

    template <typename TEA>
    static double GetTotalTicketsEquityPercentChange(TEA &ea, double startingEquity, ObjectList<Ticket> &tickets);

    template <typename TEA>
    static bool TicketStopLossIsMovedToBreakEven(TEA &ea, Ticket &ticket);
};

/*

   _   _      _                   __  __      _   _               _
  | | | | ___| |_ __   ___ _ __  |  \/  | ___| |_| |__   ___   __| |___
  | |_| |/ _ \ | '_ \ / _ \ '__| | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  |  _  |  __/ | |_) |  __/ |    | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_| |_|\___|_| .__/ \___|_|    |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
               |_|

*/
bool EAOrderHelper::LotSizeIsInvalid(string symbol, TicketType type, double lotSize)
{
    // make sure we are not about to go over the max allowed lots for a single symbol at once
    double maxLots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
    if (maxLots > 0)
    {
        double totalLots = OrderInfoHelper::GetTotalLotsForSymbolAndDirection(symbol, type);
        if (lotSize + totalLots > maxLots)
        {
            Print("Lotsize: ", lotSize, " would go over the max allowed lot size for this symbol");
            return true;
        }
    }

    return false;
}

double EAOrderHelper::GetLotSizeForRiskPercent(string symbol, double stopLossPips, double riskPercent)
{
    double pipValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE) * 10 * SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    // since UJ starts with USD, it also involves the current price
    // TODO: update this to catch any other pairs
    if (StringFind(symbol, "JPY") != -1)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(symbol, currentTick))
        {
            Print("Can't get tick during lot size calculation");
            return 0;
        }

        pipValue = pipValue / currentTick.bid;
    }

    return NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent / 100) / (stopLossPips * pipValue), 2);
}

static void EAOrderHelper::CheckBreakLotSizeUp(string symbol, double originalLotSize, int &numberOfOrders, double &lotSizeToUse)
{
    numberOfOrders = 1;
    lotSizeToUse = originalLotSize;

    double maxLotSize = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    while (lotSizeToUse > maxLotSize)
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

    if (ea.mCurrentSetupTicket.Number() != ConstantValues::EmptyInt)
    {
        return false;
    }

    ea.mLastState = EAStates::COUNTING_OTHER_EA_ORDERS;

    if (ea.MaxTradesForEAGroup() != ConstantValues::EmptyInt)
    {
        int orders = 0;
        int ordersError = OrderInfoHelper::CountOtherEAOrders(true, ea.mEAGroupMagicNumbers, orders);
        if (ordersError != Errors::NO_ERROR)
        {
            ea.InvalidateSetup(false, ordersError);
            return false;
        }

        if (orders >= ea.MaxTradesForEAGroup())
        {
            ea.InvalidateSetup(false);
            return false;
        }
    }

    return true;
}

template <typename TEA>
static void EAOrderHelper::PostPlaceOrderChecks(TEA &ea, string methodName, int ticketNumber, int error, TicketType ticketType, double expectedEntry, double stopLoss,
                                                double lotSize, double takeProfit, double accountBalanceBefore)
{
    if (ticketNumber == ConstantValues::EmptyInt)
    {
        string orderInfo =
            "Method: " + methodName +
            " Magic Number: " + IntegerToString(ea.MagicNumber()) +
            " Type: " + IntegerToString(ticketType) +
            " Ask: " + DoubleToString(ea.CurrentTick().Ask()) +
            " Bid: " + DoubleToString(ea.CurrentTick().Bid()) +
            " Entry: " + DoubleToString(expectedEntry) +
            " Stop Loss: " + DoubleToString(stopLoss) +
            " Lot Size: " + DoubleToString(lotSize) +
            " Take Profit: " + DoubleToString(takeProfit);

        ea.RecordError(__FUNCTION__, error, orderInfo);
        return;
    }

    Ticket *ticket = new Ticket(ticketNumber);
    ticket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);
    ticket.ExpectedOpenPrice(expectedEntry);
    ticket.AccountBalanceBefore(accountBalanceBefore);

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
static void EAOrderHelper::InternalPlaceMarketOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, double takeProfit)
{
    int ticket = ConstantValues::EmptyInt;
    double accountBalanceBefore = AccountInfoDouble(ACCOUNT_BALANCE);
    int orderPlaceError = ea.mTM.PlaceMarketOrder(ticketType, lotSize, entryPrice, stopLoss, takeProfit, ticket);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, ticketType, entryPrice, stopLoss, lotSize, takeProfit, accountBalanceBefore);
}

template <typename TEA>
static void EAOrderHelper::PlaceMarketOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, double takeProfit = 0.0,
                                            TicketType orderTypeOverride = TicketType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    TicketType ticketType = orderTypeOverride;
    if (ticketType == TicketType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            ticketType = TicketType::Buy;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            ticketType = TicketType::Sell;
        }
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    if (LotSizeIsInvalid(ea.EntrySymbol(), ticketType, lotSize))
    {
        return;
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(ea.EntrySymbol(), lotSize, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceMarketOrder(ea, ticketType, entryPrice, stopLoss, lotsToUse, takeProfit);
    }
}

template <typename TEA>
static void EAOrderHelper::InternalPlaceLimitOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, bool fallbackMarketOrder,
                                                   double maxMarketOrderSlippage)
{
    int ticket = ConstantValues::EmptyInt;
    int orderPlaceError = Errors::NO_ERROR;
    double accountBalanceBefore = AccountInfoDouble(ACCOUNT_BALANCE);

    if (ticketType == TicketType::BuyLimit)
    {
        if (fallbackMarketOrder && entryPrice >= ea.CurrentTick().Ask() && ea.CurrentTick().Ask() - entryPrice <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(TicketType::Buy, lotSize, ea.CurrentTick().Ask(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceLimitOrder(ticketType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }
    else if (ticketType == TicketType::SellLimit)
    {
        if (fallbackMarketOrder && entryPrice <= ea.CurrentTick().Bid() && entryPrice - ea.CurrentTick().Bid() <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(TicketType::Buy, lotSize, ea.CurrentTick().Bid(), stopLoss, 0, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceLimitOrder(ticketType, lotSize, entryPrice, stopLoss, 0, ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, ticketType, entryPrice, stopLoss, lotSize, 0, accountBalanceBefore);
}

template <typename TEA>
static void EAOrderHelper::PlaceLimitOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, bool fallbackMarketOrder = false,
                                           double maxMarketOrderSlippage = 0.0, TicketType orderTypeOverride = TicketType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    TicketType limitType = orderTypeOverride;
    if (limitType == TicketType::Empty)
    {
        if (ea.SetupType() == TicketType::Bullish)
        {
            limitType = TicketType::BuyLimit;
        }
        else if (ea.SetupType() == TicketType::Bearish)
        {
            limitType = TicketType::SellLimit;
        }
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    if (LotSizeIsInvalid(ea.EntrySymbol(), limitType, lotSize))
    {
        return;
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(ea.EntrySymbol(), lots, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceLimitOrder(ea, limitType, entryPrice, stopLoss, lotsToUse, fallbackMarketOrder, maxMarketOrderSlippage);
    }
}

template <typename TEA>
static void EAOrderHelper::InternalPlaceStopOrder(TEA &ea, TicketType ticketType, double entryPrice, double stopLoss, double lotSize, double takeProfit,
                                                  bool fallbackMarketOrder, double maxMarketOrderSlippage)
{
    int ticket = ConstantValues::EmptyInt;
    int orderPlaceError = Errors::NO_ERROR;
    double accountBalanceBefore = AccountInfoDouble(ACCOUNT_BALANCE);

    if (ticketType == TicketType::BuyStop)
    {
        if (fallbackMarketOrder && entryPrice <= ea.CurrentTick().Ask() && ea.CurrentTick().Ask() - entryPrice <= PipConverter::PipsToPoints(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(TicketType::Buy, lotSize, ea.CurrentTick().Ask(), stopLoss, takeProfit, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(ticketType, lotSize, entryPrice, stopLoss, takeProfit, ticket);
        }
    }
    else if (ticketType == TicketType::SellStop)
    {
        if (fallbackMarketOrder && entryPrice >= ea.CurrentTick().Bid() && entryPrice - ea.CurrentTick().Bid() <= PipConverter::PipsToPoints(maxMarketOrderSlippage))
        {
            orderPlaceError = ea.mTM.PlaceMarketOrder(TicketType::Sell, lotSize, ea.CurrentTick().Bid(), stopLoss, takeProfit, ticket);
        }
        else
        {
            orderPlaceError = ea.mTM.PlaceStopOrder(ticketType, lotSize, entryPrice, stopLoss, takeProfit, ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticket, orderPlaceError, ticketType, entryPrice, stopLoss, lotSize, takeProfit, accountBalanceBefore);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrder(TEA &ea, double entryPrice, double stopLoss, double lotSize = 0.0, double takeProfit = 0.0, bool fallbackMarketOrder = false,
                                          double maxMarketOrderSlippage = 0.0, TicketType orderTypeOverride = TicketType::Empty)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    TicketType stopType = orderTypeOverride;
    if (stopType == TicketType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            stopType = TicketType::BuyStop;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            stopType = TicketType::SellStop;
        }
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    if (LotSizeIsInvalid(ea.EntrySymbol(), stopType, lotSize))
    {
        return;
    }

    int numberOfOrdersToPlace;
    double lotsToUse;
    CheckBreakLotSizeUp(ea.EntrySymbol(), lotSize, numberOfOrdersToPlace, lotsToUse);

    for (int i = 0; i < numberOfOrdersToPlace; i++)
    {
        InternalPlaceStopOrder(ea, stopType, entryPrice, stopLoss, lotsToUse, takeProfit, fallbackMarketOrder, maxMarketOrderSlippage);
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
static int EAOrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, SignalType setupType, MBTracker *&mbt, double &entryPrice)
{
    entryPrice = 0.0;
    int retracementIndex = ConstantValues::EmptyInt;

    if (setupType == SignalType::Bullish)
    {
        // don't allow an order to be placed unless we have a pending mb and valid retracement
        if (!mbt.HasPendingBullishMB() || !mbt.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return Errors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // only add spread to buys since we want to enter as the bid hits our entry
        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) + PipConverter::PipsToPoints(spreadPips);
    }
    else if (setupType == SignalType::Bearish)
    {
        if (!mbt.HasPendingBearishMB() || !mbt.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return Errors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // move the entry down 0.1 pips so that we only get entered if we actually validate the mb and if we just tap the range
        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), retracementIndex) - PipConverter::PipsToPoints(0.1);
    }

    return Errors::NO_ERROR;
}

static int EAOrderHelper::GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, SignalType setupType, MBTracker *&mbt, double &stopLoss)
{
    stopLoss = 0.0;
    int retracementIndex = ConstantValues::EmptyInt;

    if (setupType == SignalType::Bullish)
    {
        // don't allow an order to be placed unless we have a pending mb and valid retracement
        // TODO: move this check somewhere else
        if (!mbt.HasPendingBullishMB() || !mbt.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return Errors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // subtract one so that we can't include the imbalance candle as the lowest
        double low = 0.0;
        if (!MQLHelper::GetLowestLowBetween(mbt.Symbol(), mbt.TimeFrame(), retracementIndex, 0, true, low))
        {
            return Errors::COULD_NOT_RETRIEVE_LOW;
        }

        stopLoss = low - PipConverter::PipsToPoints(paddingPips);
    }
    else if (setupType == SignalType::Bearish)
    {
        if (!mbt.HasPendingBearishMB() || !mbt.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return Errors::BULLISH_RETRACEMENT_IS_NOT_VALID;
        }

        // subtract one so that we can't include the imbalance candle as the highest
        double high = 0.0;
        if (!MQLHelper::GetHighestHighBetween(mbt.Symbol(), mbt.TimeFrame(), retracementIndex, 0, true, high))
        {
            return Errors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss = high + PipConverter::PipsToPoints(paddingPips + spreadPips);
    }

    return Errors::NO_ERROR;
}

static int EAOrderHelper::GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, double &entryPrice)
{
    entryPrice = 0.0;

    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == SignalType::Bullish)
    {
        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex());
    }
    else if (tempMBState.Type() == SignalType::Bearish)
    {
        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex()) + PipConverter::PipsToPoints(spreadPips);
    }

    return Errors::NO_ERROR;
}

static int EAOrderHelper::GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, double &stopLoss)
{
    stopLoss = 0.0;
    MBState *tempMBState;

    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == SignalType::Bullish)
    {
        double high;
        if (!MQLHelper::GetHighestHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.EndIndex(), 0, true, high))
        {
            return Errors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss = high + PipConverter::PipsToPoints(paddingPips + spreadPips);
    }
    else if (tempMBState.Type() == SignalType::Bearish)
    {
        double low = 0.0;
        if (!MQLHelper::GetLowestLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.EndIndex(), 0, true, low))
        {
            return Errors::COULD_NOT_RETRIEVE_LOW;
        }

        stopLoss = low - PipConverter::PipsToPoints(paddingPips);
    }

    return Errors::NO_ERROR;
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, double lotSize = 0.0)
{
    TicketType ticketType = TicketType::Empty;
    if (ea.SetupType() == SignalType::Bullish)
    {
        ticketType = TicketType::BuyStop;
    }
    else if (ea.SetupType() == SignalType::Bearish)
    {
        ticketType = TicketType::SellStop;
    }

    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, mbt.GetNthMostRecentMBsType(0), mbt, entryPrice);
    if (entryPriceError != Errors::NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, mbt.GetNthMostRecentMBsType(0), mbt, stopLoss);
    if (stopLossError != Errors::NO_ERROR)
    {
        return stopLossError;
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int ticketNumber = ConstantValues::EmptyInt;
    int error = ea.mTM.PlaceStopOrder(ticketType, lotSize, entryPrice, stopLoss, 0, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, error, ticketType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber, double lotSize = 0.0)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderForBreakOfMB(spreadPips, mbNumber, mbt, entryPrice);
    if (entryPriceError != Errors::NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, mbNumber, mbt, stopLoss);
    if (stopLossError != Errors::NO_ERROR)
    {
        return stopLossError;
    }

    TicketType ticketType = TicketType::Empty;
    if (tempMBState.Type() == SignalType::Bullish)
    {
        ticketType = TicketType::SellStop;
    }
    else if (tempMBState.Type() == SignalType::Bearish)
    {
        ticketType = TicketType::BuyStop;
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), ea.RiskPercent());
    }

    int ticketNumber = ConstantValues::EmptyInt;
    int orderPlaceError = ea.mTM.PlaceStopOrder(ticketType, lotSize, entryPrice, stopLoss, 0, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, orderPlaceError, ticketType, entryPrice, stopLoss, lotSize, 0);
}

template <typename TEA>
static void EAOrderHelper::PlaceStopOrderForCandelBreak(TEA &ea, int entryCandleIndex, int stopLossCandleIndex, double takeProfit = 0.0,
                                                        TicketType ticketType = TicketType::Empty, double lotSize = 0.0)
{
    double entryPrice;
    double stopLoss;

    TicketType type = ticketType;
    if (type == TicketType::Empty)
    {
        if (ea.SetupType() == SignalType::Bullish)
        {
            type = TicketType::BuyStop;
        }
        else if (ea.SetupType() == SignalType::Bearish)
        {
            type = TicketType::SellStop;
        }
    }

    if (type == TicketType::BuyStop)
    {
        entryPrice = iHigh(symbol, timeFrame, entryCandleIndex);
        stopLoss = iLow(symbol, timeFrame, stopLossCandleIndex);
    }
    else if (type == TicketType::SellStop)
    {
        entryPrice = iLow(symbol, timeFrame, entryCandleIndex);
        stopLoss = iHigh(symbol, timeFrame, stopLossCandleIndex);
    }

    if (lotSize == 0.0)
    {
        lotSize = GetLotSizeForPercentRisk(PipConverter::PointsToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    }

    int ticketNumber = ConstantValues::EmptyInt;
    int orderPlaceError = ea.mTM.PlaceStopOrder(type, lots, entryPrice, stopLoss, takeProfit, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, __FUNCTION__, ticketNumber, orderPlaceError, ticketType, entryPrice, stopLoss, lotSize, takeProfit);
}

template <typename TEA>
static void EAOrderHelper::MimicOrders(TEA &ea)
{
    if (OrderInfoHelper::TotalCurrentOrders() > ea.mCurrentSetupTickets.Size())
    {
        List<int> *tickets = new List<int>();
        OrderInfoHelper::GetAllActiveTickets(tickets);

        for (int i = 0; i < tickets.Size(); i++)
        {
            if (!ea.mCurrentSetupTickets.Contains<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, tickets[i]))
            {
                Ticket *ticket = new Ticket(tickets[i]);
                ticket.AccountBalanceBefore(AccountInfoDouble(ACCOUNT_BALANCE));
                ea.mCurrentSetupTickets.Add(ticket);
            }
        }

        delete tickets;
    }
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
    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool isActive = false;
    int isActiveError = ticket.IsActive(isActive);
    if (Errors::IsTerminalError(isActiveError))
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
    if (Errors::IsTerminalError(stopLossIsMovedToBreakEvenError))
    {
        ea.RecordError(__FUNCTION__, stopLossIsMovedToBreakEvenError);
        return;
    }

    if (stopLossIsMovedBreakEven)
    {
        return;
    }

    TicketType type = ticket.Type();
    if (type != TicketType::Buy && type != TicketType::Sell)
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
    if (type == TicketType::Buy)
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
    if (error != Errors::NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, error);
    }
}

template <typename TEA>
void EAOrderHelper::MoveTicketToBreakEvenWhenCandleClosesPastEntry(TEA &ea, Ticket &ticket)
{
    TicketType ticketType = ticket.Type();
    bool furtherThanEntry = false;

    if (ticketType == TicketType::Buy)
    {
        furtherThanEntry = iLow(symbol, timeFrame, index) > ticket.OpenPrice();
    }
    else if (ticketType == TicketType::Sell)
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

            double newTicketNumber = ConstantValues::EmptyInt;
            double lotSize = GetLotSizeForRiskPercent(ea.EntrySymbol(), PipConverter::PointsToPips(MathAbs(ticket.OpenPrice() - newStopLoss)), ea.RiskPercent());
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
    TicketType ticketType = ticket.Type();

    double newStopLoss = ticket.CurrentStopLoss();
    if (ticketType == TicketType::BuyStop)
    {
        double low = iLow(symbol, timeFrame, 0);
        if (low < newStopLoss)
        {
            newStopLoss = low - PipConverter::PipsToPoints(ea.StopLossPaddingPips());
        }
    }
    else if (ticketType == TicketType::SellStop)
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
    TicketType ticketType = ticket.Type();
    if (ticketType != TicketType::Buy && ticketType != TicketType::Sell)
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
    TicketType ticketType = ticket.Type();
    if (ticketType != TicketType::Buy && ticketType != TicketType::Sell)
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
    TicketType ticketType = ticket.Type();
    if (ticketType != TicketType::Buy && ticketType != TicketType::Sell)
    {
        return;
    }

    MBState *tempMBState;
    if (!mbt.GetNthMostRecentMB(0, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
    }

    // only trail with same type MBs
    if ((ticketType == TicketType::Buy && tempMBState.Type() != SignalType::Bullish) ||
        (ticketType == TicketType::Sell && tempMBState.Type() != SignalType::Bearish))
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
        if (Errors::IsTerminalError(error))
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
        if (Errors::IsTerminalError(error))
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
/*

   __  __                                   _        _   _             _____ _      _        _
  |  \/  | __ _ _ __   __ _  __ _  ___     / \   ___| |_(_)_   _____  |_   _(_) ___| | _____| |_
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \   / _ \ / __| __| \ \ / / _ \   | | | |/ __| |/ / _ \ __|
  | |  | | (_| | | | | (_| | (_| |  __/  / ___ \ (__| |_| |\ V /  __/   | | | | (__|   <  __/ |_
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___| /_/   \_\___|\__|_| \_/ \___|   |_| |_|\___|_|\_\___|\__|
                            |___/

*/
template <typename TEA>
static void EAOrderHelper::CheckTrailStopLossEveryXPips(TEA &ea, Ticket &ticket, double everyXPips, double trailBehindPips)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (trailBehindPips >= everyXPips)
    {
        Print("Trail behind pips cannot be greater than or equal to everyXPips. Our SL would be past or equal to price");
        return;
    }

    double startPips = 0.0;
    double newSL = 0.0;

    double openPrice = ticket.OpenPrice();
    double currentStopLoss = ticket.CurrentStopLoss();

    if (ticket.Type() == TicketType::Buy)
    {
        // only want to trail if we run everyxPips past entry, not right away
        startPips = MathMax(openPrice, currentStopLoss);
        if (ea.CurrentTick().Bid() - startPips >= PipConverter::PipsToPoints(everyXPips))
        {
            if (openPrice > currentStopLoss)
            {
                newSL = openPrice;
            }
            else
            {
                newSL = NormalizeDouble(startPips + PipConverter::PipsToPoints(trailBehindPips), Digits);
            }

            int error = ea.mTM.ModifyOrder(ticket.Number(), openPrice, newSL, ticket.TakeProfit() ticket.Expiration());
            if (Errors::IsTerminalError(error))
            {
                ea.RecordError(__FUNCTION__, error);
            }
        }
    }
    else if (ticket.Type() == TicketType::Sell)
    {
        // only want to trail if we run everyxPips past entry, not right away
        startPips = MathMin(openPrice, currentStopLoss);
        if (startPips - ea.CurrentTick().Bid() >= PipConverter::PipsToPoints(everyXPips))
        {
            if (openPrice < currentStopLoss)
            {
                newSL = openPrice;
            }
            else
            {
                newSL = NormalizeDouble(startPips - PipConverter::PipsToPoints(trailBehindPips), Digits);
            }

            int error = ea.mTM.OrderModify(ticket.Number(), openPrice, newSL, ticket.TakeProfit(), ticket.Expiration());
            if (Errors::IsTerminalError(error))
            {
                ea.RecordError(__FUNCTION__, error);
            }
        }
    }
}

template <typename TEA>
static void EAOrderHelper::MoveToBreakEvenAfterPips(TEA &ea, Ticket &ticket, double pipsToWait, double additionalPips = 0.0)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    bool movedPips = false;
    if (ticket.Type() == TicketType::Buy)
    {
        movedPips = ea.CurrentTick().Bid() - ticket.OpenPrice() >= PipConverter::PipsToPoints(pipsToWait);
    }
    else if (ticket.Type() == TicketType::Sell)
    {
        movedPips = ticket.OpenPrice() - ea.CurrentTick().Ask() >= PipConverter::PipsToPoints(pipsToWait);
    }

    if (movedPips)
    {
        MoveTicketToBreakEven(ea, ticket, additionalPips);
    }
}

template <typename TEA>
static void EAOrderHelper::MoveToBreakEvenAfterNextSameTypeMBValidation(TEA &ea, Ticket &ticket, MBTracker *&mbt, int entryMB)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    MBState *mostRecentMB;
    if (!mbt.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    if (mostRecentMB.Number() == entryMB)
    {
        return;
    }

    MBState *entryMBState;
    if (!mbt.GetMB(entryMB, entryMBState))
    {
        return;
    }

    if (mostRecentMB.Type() != entryMBState.Type())
    {
        return;
    }

    MoveTicketToBreakEven(ea, ticket);
}

template <typename TEA>
static void EAOrderHelper::MoveToBreakEvenWithCandleCloseFurtherThanEntry(TEA &ea, Ticket &ticket, double additionalPips)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    int entryIndex = iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime());
    if (entryIndex <= 0)
    {
        return;
    }

    bool moveToBreakEven = false;
    if (ticket.Type() == TicketType::Buy)
    {
        for (int i = 1; i <= entryIndex; i++)
        {
            if (iClose(ea.EntrySymbol(), ea.EntryTimeFrame(), i) > ticket.OpenPrice())
            {
                moveToBreakEven = true;
                break;
            }
        }
    }
    else if (ticket.Type() == TicketType::Sell)
    {
        for (int i = 1; i <= entryIndex; i++)
        {
            if (iClose(ea.EntrySymbol(), ea.EntryTimeFrame(), i) < ticket.OpenPrice())
            {
                moveToBreakEven = true;
                break;
            }
        }
    }

    if (moveToBreakEven)
    {
        MoveTicketToBreakEven(ea, ticket, additionalPips);
    }
}

/**
 * @brief Checks / partials a ticket. Should only be called if an EA has at least one partial set via EA.SetPartial() in a Startegy.mqh
 * Will break if the last partial is not set to 100%
 * @tparam TEA
 * @param ea
 * @param ticketIndex
 */
template <typename TEA>
static void EAOrderHelper::CheckPartialTicket(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_TO_PARTIAL;

    if (ticket.mPartials.Size() == 0)
    {
        // this should never happen unless the EA is set up wrong
        // we won't return here so that we intentially cause an index out of range exception below
        Print("Ticket has no partials");
    }

    // if we are in a buy, we look to sell which occurs at the bid. If we are in a sell, we look to buy which occurs at the ask
    double currentPrice = ea.SetupType() == SignalType::Bullish ? ea.CurrentTick().Bid() : ea.CurrentTick().Ask();
    double rr = MathAbs(currentPrice - ticket.OpenPrice()) / MathAbs(ticket.OpenPrice() - ticket.OriginalStopLoss());

    if (rr < ticket.mPartials[0].mRR)
    {
        return;
    }

    // store lots since I don't think i'll be able to access it once I partial the ticket
    double currentTicketLots = ticket.LotSize();
    double lotsToPartial = 0.0;

    // if we are planning on closing the ticket we need to make sure we do or else this will break
    // aka don't risk a potential rounding issue and just use the current lots
    if (ticket.mPartials[0].PercentAsDecimal() >= 1)
    {
        lotsToPartial = currentTicketLots;
    }
    else
    {
        lotsToPartial = ea.mTM.CleanLotSize(currentTicketLots * ticket.mPartials[0].PercentAsDecimal());
    }

    int partialError = ticket.Partial(currentPrice, lotsToPartial);
    if (partialError != Errors::NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, partialError);
        return;
    }

    ticket.RRAcquired(rr * ticket.mPartials[0].PercentAsDecimal());
    int newTicket = 0;

    // this is probably the safest way of checking if the order was closed
    // can't use partial percent since closing less than 100% could still result in the whole ticket being closed due to min lot size
    // can't check to see if the ticket is opened since we don't know what ticket it is anymore
    // can't rely on not being able to find it because something else could go wrong
    if (lotsToPartial != currentTicketLots)
    {
        ea.mLastState = EAStates::SEARCHING_FOR_PARTIALED_TICKET;

        int searchError = OrderInfoHelper::FindNewTicketAfterPartial(ea.MagicNumber(), ticket.OpenPrice(), ticket.OpenTime(), newTicket);
        if (searchError != Errors::NO_ERROR)
        {
            ea.RecordError(__FUNCTION__, searchError);
        }

        // record before setting the new ticket or altering the old tickets partials
        ea.RecordTicketPartialData(ticket, newTicket);

        if (newTicket == ConstantValues::EmptyInt)
        {
            ea.RecordError(__FUNCTION__, Errors::UNABLE_TO_FIND_PARTIALED_TICKET);
        }
        else
        {
            ticket.UpdateTicketNumber(newTicket);
        }

        ticket.mPartials.Remove(0);
    }
    else
    {
        ea.RecordTicketPartialData(ticket, newTicket);
    }
}

template <typename TEA>
static void EAOrderHelper::CloseIfPriceCrossedTicketOpen(TEA &ea, Ticket &ticket, int candlesAfterOpen)
{
    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return;
    }

    int entryIndex = iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime());
    if (entryIndex < candlesAfterOpen)
    {
        return;
    }

    if (ticket.Type() == TicketType::Buy && ea.CurrentTick().Bid() < ticket.OpenPrice())
    {
        ticket.Close();
    }
    else if (ticket.Type() == TicketType::Sell && ea.CurrentTick().Ask() > ticket.OpenPrice())
    {
        ticket.Close();
    }
}

template <typename TEA>
void EAOrderHelper::MoveStopLossToCoverCommissions(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_COVERING_COMMISSIONS;

    int costPerLot = ticket.Commissions();
    double totalCost = ticket.LotSize() * costPerLot;
    double profitPerTick = MarketInfo(ea.EntrySymbol(), MODE_LOTSIZE) * MarketInfo(ea.EntrySymbol(), MODE_TICKSIZE);

    bool aboveCommissionCosts = false;
    double coveredCommisssionsPrice = 0.0;

    if (ticket.Type() == TicketType::Buy)
    {
        double profit = ((ea.CurrentTick().Bid() - ticket.OpenPrice()) / MarketInfo(ea.EntrySymbol(), MODE_TICKSIZE)) * profitPerTick;
        if (profit >= totalCost)
        {
            aboveCommissionCosts = true;
            coveredCommisssionsPrice = (MarketInfo(ea.EntrySymbol(), MODE_TICKSIZE) * (totalCost / profitPerTick)) + ticket.OpenPrice();
        }
    }
    else if (ticket.Type() == TicketType::Sell)
    {
        double profit = ((ticket.OpenPrice() - ea.CurrentTick().Ask()) / MarketInfo(ea.EntrySymbol(), MODE_TICKSIZE)) * profitPerTick;
        if (profit >= totalCost)
        {
            aboveCommissionCosts = true;
            coveredCommisssionsPrice = ticket.OpenPrice() - (MarketInfo(ea.EntrySymbol(), MODE_TICKSIZE) * (totalCost / profitPerTick));
        }
    }

    if (NormalizeDouble(coveredCommisssionsPrice, Digits) == NormalizeDouble(ticket.CurrentStopLoss(), Digits))
    {
        return;
    }

    if (aboveCommissionCosts)
    {
        int error = ea.mTM.OrderModify(ticket.Number(), ticket.OpenPrice(), coveredCommisssionsPrice, ticket.TakeProfit(), ticket.Expiration());
        if (Errors::IsTerminalError(error))
        {
            ea.RecordError(__FUNCTION__, error);
        }
    }
}

template <typename TEA>
static bool EAOrderHelper::CloseIfPercentIntoStopLoss(TEA &ea, Ticket &ticket, double percentAsDecimal)
{
    bool stopLossIsMovedBreakEven;
    int stopLossIsMovedToBreakEvenError = ticket.StopLossIsMovedToBreakEven(stopLossIsMovedBreakEven);
    if (Errors::IsTerminalError(stopLossIsMovedToBreakEvenError))
    {
        ea.RecordError(__FUNCTION__, stopLossIsMovedToBreakEvenError);
        return false;
    }

    // this function will always close the ticket if our SL is at or further than our entry price
    if (stopLossIsMovedBreakEven)
    {
        return false;
    }

    bool isPercentIntoStopLoss = false;
    if (ticket.Type() == TicketType::Buy)
    {
        isPercentIntoStopLoss = (ticket.OpenPrice() - ea.CurrentTick().Bid()) / (ticket.OpenPrice() - ticket.CurrentStopLoss()) >= percentAsDecimal;
    }
    else if (ticket.Type() == TicketType::Sell)
    {
        isPercentIntoStopLoss = (ea.CurrentTick().Ask() - ticket.OpenPrice()) / (ticket.CurrentStopLoss() - ticket.OpenPrice()) >= percentAsDecimal;
    }

    if (isPercentIntoStopLoss)
    {
        ticket.Close();
        return true;
    }

    return false;
}

template <typename TEA>
static bool EAOrderHelper::CloseTicketIfPastTime(TEA &ea, Ticket &ticket, int hour, int minute, bool fallbackCloseIfNewDay = true)
{
    if ((Hour() >= hour && Minute() >= minute) || (fallbackCloseIfNewDay && Day() != ea.LastDay()))
    {
        ticket.Close();
        return true;
    }

    return false;
}

template <typename TEA>
static double EAOrderHelper::GetTotalTicketsEquityPercentChange(TEA &ea, double startingEquity, ObjectList<Ticket> &tickets)
{
    double profits = 0.0;
    for (int i = 0; i < tickets.Size(); i++)
    {
        profits += tickets[i].Profit();
    }

    double finalEquity = startingEquity + profits;

    // can happen if we don't have any tickets and we haven't set the starting equity yet
    if (finalEquity == 0)
    {
        return 0;
    }

    return (finalEquity - startingEquity) / finalEquity * 100;
}

template <typename TEA>
static bool EAOrderHelper::TicketStopLossIsMovedToBreakEven(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN;
    if (ticket.Number() == ConstantValues::EmptyInt)
    {
        return false;
    }

    bool stopLossIsMovedToBreakEven = false;
    int error = ticket.StopLossIsMovedToBreakEven(stopLossIsMovedToBreakEven);
    if (Errors::IsTerminalError(error))
    {
        ea.RecordError(__FUNCTION__, error);
    }

    return stopLossIsMovedToBreakEven;
}