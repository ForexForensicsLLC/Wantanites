//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Ticket.mqh>
#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Constants\Index.mqh>

class OrderHelper
{
protected:
    // ==========================================================================
    // Error Handling
    // ==========================================================================
    // !Tested
    static void SendFailedOrderEMail(int orderNumber, int orderType, double entryPrice, double stopLoss, double lots, int magicNumber, int error);

    // !Tested
    static void SendMBFailedOrderEmail(int error, MBTracker *&mbt);

public:
    // ==========================================================================
    // Calculating Orders
    // ==========================================================================
    // Tested
    static double RangeToPips(double range);

    // Tested
    static double PipsToRange(double pips);

    // Tested
    static double GetLotSize(double stopLossPips, double riskPercent);

    static double CleanLotSize(double dirtyLotSize);

private:
    // Tested
    // ResetsOutParam
    static int GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, int setupType, MBTracker *&mbt, out double &entryPrice);

    // Tested
    // ResetsOutParam
    static int GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, out double &stopLoss);

    // Tested
    // ResetsOutParam
    static int GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, out double &entryPrice);

    // Tested
    // ResetsOutParam
    static int GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, out double &stopLoss);

public:
    // ==========================================================================
    // Checking Orders
    // ==========================================================================
    // Tested
    // ResetsOutParam
    static int CountOtherEAOrders(bool todayOnly, int &magicNumbers[], out int &orders);

    // !Tested
    static int FindActiveTicketsByMagicNumber(bool todayOnly, int magicNumber, int &tickets[]);

    static int FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket);

    // =========================================================================
    // Placing Market Orders
    // =========================================================================
    static int PlaceMarketOrder(int orderType, double lots, double entry, double stoploss, double takeProfit, int magicNumber, int &ticket);
    static int PlaceMarketOrderForCandleSetup(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type,
                                              string symbol, int timeFrame, int stopLossCandleIndex, int &ticketNumber);

    static int PlaceMarketOrderForMostRecentMB(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type,
                                               int mbNumber, MBTracker *&mbt, int &ticketNumber);

    // ==========================================================================
    // Placing Limit Orders
    // ==========================================================================
    // !Tested
    // static bool PlaceLimitOrderWithSinglePartial(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, double partialOnePercent, int magicNumber);

    // ==========================================================================
    // Placing Stop Orders
    // ==========================================================================
    // Tested
    // ResetsOutParam
    static int PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber, int &ticket);

    static int PlaceStopOrderForCandleBreak(double paddingPips, double spreadPips, double riskPercent, int magicNumber,
                                            int type, string symbol, int timeFrame, int entryCandleIndex, int stopLossCandleIndex, int &ticketNumber);

    static int PlaceStopOrderForTheLittleDipper(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type, string symbol, int timeFrame,
                                                int &ticketNumber);

    // ==========================================================================
    // Placing Stop Orders on MBs
    // ==========================================================================
    // Tested
    // ResetsOutParam
    static int PlaceStopOrderForPendingMBValidation(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int setupMBNumber,
                                                    MBTracker *&mbt, out int &ticket);

    // Tested
    // ResetsOutParam
    static int PlaceStopOrderForBreakOfMB(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker *&mbt, out int &ticket);

    static int PlaceStopOrderForPendingLiquidationSetupValidation(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int liquidationMBNumber,
                                                                  MBTracker *&mbt, out int &ticket);

    // ==========================================================================
    // Editing Orders
    // ==========================================================================
    // !Tested
    // static bool EditStopLoss(double newStopLoss, double newLots, int magicNumber);

    static int PartialTicket(int ticketNumber, double price, double lotsToPartial);

    static int MoveTicketToBreakEven(Ticket &ticket, double additionalPips);

    static int MoveToBreakEvenWithCandleFurtherThanEntry(string symbol, int timeFrame, bool waitForCandleClose, Ticket *&ticket);

    static int CheckEditStopLossForTheLittleDipper(double stopLossPaddingPips, double spreadPips, string symbol, int timeFrame, Ticket &ticket);

    // ==========================================================================
    // Editing Orders For MB Stop Orders
    // ==========================================================================
    // Tested
    static int CheckEditStopLossForStopOrderOnPendingMB(double paddingPips, double spreadPips, double riskPercent,
                                                        int setupMBNumber, MBTracker *&mbt, out Ticket *&ticket);

    // !Tested
    static int CheckEditStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, double riskPercent,
                                                        int mbNumber, MBTracker *&mbt, out Ticket *&ticket);

    static int CheckEditStopLossForLiquidationMBSetup(double paddingPips, double spreadPips, double riskPercent,
                                                      int liquidationMBNumber, MBTracker *&mbt, out Ticket *&ticket);
    // ==========================================================================
    // Canceling Pending Orders
    // ==========================================================================
    // !Tested
    // static bool CancelAllPendingOrdersByMagicNumber(int magicNumber);

    // ==========================================================================
    // Moving To Break Even
    // ==========================================================================
    // !Tested
    // static bool MoveAllOrdersToBreakEvenByMagicNumber(int magicNumber);

    // ==========================================================================
    // Moving To Break Even By MB
    // ==========================================================================
    // Tested
    static int CheckTrailStopLossWithMBUpToBreakEven(double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker *&mbt, Ticket *&ticket, out bool &succeeded);
};

static double OrderHelper::CleanLotSize(double dirtyLotSize)
{
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double maxLotSize = MarketInfo(Symbol(), MODE_MAXLOT);
    double minLotSize = MarketInfo(Symbol(), MODE_MINLOT);

    // cut off extra decimal places
    double cleanedLots = NormalizeDouble(dirtyLotSize, 2);

    // make sure we are not larger than the max
    cleanedLots = MathMin(cleanedLots, maxLotSize);
    // make sure we are not lower than the min
    cleanedLots = MathMax(cleanedLots, minLotSize);

    return cleanedLots;
}
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

static void OrderHelper::SendMBFailedOrderEmail(int error, MBTracker *&mbt)
{
    SendMail("Failed to place MB order",
             "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
                 "Error: " + IntegerToString(error) + "\n" +
                 mbt.ToString());
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
    double pipValue = MarketInfo(Symbol(), MODE_TICKSIZE) * 10 * MarketInfo(Symbol(), MODE_LOTSIZE);

    // the actual pip value for JPY fluctuates based on the current price so it needs to be adjusted
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
    return CleanLotSize(lotSize);
}

/**
 * @brief Gets the entry price for a stop order that will trigger on the CONTINUTATION of the pending MB / Validation of MB
 * Can only be used if the closests valid zone is holding
 *
 * @param spreadPips
 * @param setupType
 * @param mbt
 * @param entryPrice
 * @return int
 */
static int OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(double spreadPips, int setupType, MBTracker *&mbt, out double &entryPrice)
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
/**
 * @brief Gets the stop loss for a stop order that will trigger on the CONTINUATION of the current pending MB / validation of MB
 *
 * @param paddingPips
 * @param spreadPips
 * @param setupType
 * @param mbt
 * @param stopLoss
 * @return int
 */
static int OrderHelper::GetStopLossForStopOrderForPendingMBValidation(double paddingPips, double spreadPips, int setupType, MBTracker *&mbt, out double &stopLoss)
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
/**
 * @brief Gets the entry price for a stop order that will trigger on the BREAK of the current pending MB / not holding of the previous MB
 *
 * @param spreadPips
 * @param mbNumber
 * @param mbt
 * @param entryPrice
 * @return int
 */
static int OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(double spreadPips, int mbNumber, MBTracker *&mbt, out double &entryPrice)
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
/**
 * @brief Gets the Stop Loss for a stop order that will trigger on the BREAK of the current pending MB / not holding of the previous MB
 *
 * @param paddingPips
 * @param spreadPips
 * @param mbNumber
 * @param mbt
 * @param stopLoss - The Furthest point after the previous MB Validated before price retraced and broke it
 * @return int
 */
static int OrderHelper::GetStopLossForStopOrderForBreakOfMB(double paddingPips, double spreadPips, int mbNumber, MBTracker *&mbt, out double &stopLoss)
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
/*

    ____ _               _    _                ___          _
   / ___| |__   ___  ___| | _(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  | |   | '_ \ / _ \/ __| |/ / | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |___| | | |  __/ (__|   <| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
   \____|_| |_|\___|\___|_|\_\_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                                      |___/

*/
static int OrderHelper::CountOtherEAOrders(bool todayOnly, int &magicNumbers[], out int &orders)
{
    orders = 0;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        // only check current active tickets
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Countint Other EA Orders",
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                         "Current Order Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        for (int j = 0; j < ArraySize(magicNumbers) - 1; j++)
        {
            if (OrderMagicNumber() == magicNumbers[j])
            {
                datetime openDate = OrderOpenTime();
                if (todayOnly && (TimeYear(openDate) != Year() || TimeMonth(openDate) != Month() || TimeDay(openDate) != Day()))
                {
                    continue;
                }

                orders += 1;
            }
        }
    }

    return ERR_NO_ERROR;
}

static int OrderHelper::FindActiveTicketsByMagicNumber(bool todayOnly, int magicNumber, int &tickets[])
{
    ArrayFree(tickets);
    ArrayResize(tickets, 0);

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int error = GetLastError();
            SendMail("Failed To Select Open Order By Position When Finding Active Ticks",
                     "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                         "Current Order Index: " + IntegerToString(i) + "\n" +
                         IntegerToString(error));
            return error;
        }

        if (OrderMagicNumber() == magicNumber && OrderType() < 2 && OrderCloseTime() == 0)
        {
            datetime openDate = OrderOpenTime();
            if (todayOnly && (TimeYear(openDate) != Year() || TimeMonth(openDate) != Month() || TimeDay(openDate) != Day()))
            {
                continue;
            }

            ArrayResize(tickets, ArraySize(tickets) + 1);
            tickets[ArraySize(tickets) - 1] = OrderTicket();
        }
    }

    return ERR_NO_ERROR;
}

// TODO: Move into Ticket as a static function
static int OrderHelper::FindNewTicketAfterPartial(int magicNumber, double openPrice, datetime orderOpenTime, int &ticket)
{
    int error = ERR_NO_ERROR;
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            error = GetLastError();
            SendMail("Failed To Select Order",
                     "Error: " + IntegerToString(error) + "\n" +
                         "Position: " + IntegerToString(i) + "\n" +
                         "Total Tickets: " + IntegerToString(OrdersTotal()));

            continue;
        }

        if (OrderType() > 1)
        {
            continue;
        }

        if (OrderMagicNumber() != magicNumber)
        {
            continue;
        }

        if (NormalizeDouble(OrderOpenPrice(), Digits) != NormalizeDouble(openPrice, Digits))
        {
            continue;
        }

        if (NormalizeDouble(OrderOpenTime(), Digits) != NormalizeDouble(orderOpenTime, Digits))
        {
            continue;
        }

        ticket = OrderTicket();
        break;
    }

    return error;
}
/*

   ____  _            _               __  __            _        _      ___          _
  |  _ \| | __ _  ___(_)_ __   __ _  |  \/  | __ _ _ __| | _____| |_   / _ \ _ __ __| | ___ _ __ ___
  | |_) | |/ _` |/ __| | '_ \ / _` | | |\/| |/ _` | '__| |/ / _ \ __| | | | | '__/ _` |/ _ \ '__/ __|
  |  __/| | (_| | (__| | | | | (_| | | |  | | (_| | |  |   <  __/ |_  | |_| | | | (_| |  __/ |  \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |_|  |_|\__,_|_|  |_|\_\___|\__|  \___/|_|  \__,_|\___|_|  |___/
                              |___/

*/
static int OrderHelper::PlaceMarketOrder(int orderType, double lots, double entry, double stopLoss, double takeProfit, int magicNumber, int &ticket)
{
    if (orderType >= 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    lots = CleanLotSize(lots);

    int newTicket = OrderSend(Symbol(), orderType, lots, entry, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);

    int error = ERR_NO_ERROR;
    if (newTicket == EMPTY)
    {
        error = GetLastError();
        SendFailedOrderEMail(1, orderType, entry, stopLoss, lots, magicNumber, error);
    }

    ticket = newTicket;
    return error;
}

static int OrderHelper::PlaceMarketOrderForCandleSetup(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type,
                                                       string symbol, int timeFrame, int stopLossCandleIndex, int &ticketNumber)
{
    double entryPrice;
    double stopLoss;
    int orderType;

    if (type == OP_BUY)
    {
        entryPrice = Ask;
        stopLoss = iLow(symbol, timeFrame, stopLossCandleIndex) - PipsToRange(paddingPips);
    }
    else if (type == OP_SELL)
    {
        // move the entry down 0.1 pips so that we only get entered if we actually break below and not if we just tap it
        entryPrice = Bid;
        stopLoss = iHigh(symbol, timeFrame, stopLossCandleIndex) + PipsToRange(spreadPips + paddingPips);
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int newTicket = OrderSend(symbol, type, lots, entryPrice, 0, stopLoss, 0, NULL, magicNumber, 0, clrNONE);

    int error = ERR_NO_ERROR;
    if (newTicket == EMPTY)
    {
        error = GetLastError();
        SendFailedOrderEMail(1, type, entryPrice, stopLoss, lots, magicNumber, error);
    }

    ticketNumber = newTicket;
    return error;
}

static int OrderHelper::PlaceMarketOrderForMostRecentMB(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type,
                                                        int mbNumber, MBTracker *&mbt, int &ticketNumber)
{
    MBState *tempMBState;
    if (!mbt.MBIsMostRecent(mbNumber, tempMBState))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    double entryPrice = tempMBState.Type() == OP_BUY ? Bid : Ask;
    double stopLoss = 0.0;

    if (tempMBState.Type() == OP_BUY)
    {
        entryPrice = Ask;
        if (!MQLHelper::GetLowestLowBetween(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.StartIndex(), 0, true, stopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
        }
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        entryPrice = Bid;
        if (!MQLHelper::GetHighestHighBetween(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.StartIndex(), 0, true, stopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int ticket = OrderSend(Symbol(), tempMBState.Type(), lots, entryPrice, 0, stopLoss, 0, NULL, magicNumber, 0, clrNONE);
    if (ticket == EMPTY)
    {
        // TODO email;
        return GetLastError();
    }

    ticketNumber = ticket;
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
int OrderHelper::PlaceStopOrder(int orderType, double lots, double entryPrice, double stopLoss, double takeProfit, int magicNumber, out int &ticket)
{
    if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if ((orderType == OP_BUYSTOP && stopLoss >= entryPrice) || (orderType == OP_SELLSTOP && stopLoss <= entryPrice))
    {
        return TerminalErrors::STOPLOSS_PAST_ENTRY;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    if ((orderType == OP_BUYSTOP && entryPrice <= currentTick.ask) || (orderType == OP_SELLSTOP && entryPrice >= currentTick.bid))
    {
        Print("Type: ", orderType, ", Entry: ", entryPrice, ", SL:", stopLoss, ", Ask: ", currentTick.ask, ", Bid: ", currentTick.bid);
        return ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
    }

    lots = CleanLotSize(lots);

    int error = ERR_NO_ERROR;
    int ticketNumber = OrderSend(NULL, orderType, lots, entryPrice, 0, stopLoss, takeProfit, NULL, magicNumber, 0, clrNONE);

    if (ticketNumber < 0)
    {
        error = GetLastError();
        SendFailedOrderEMail(1, orderType, entryPrice, stopLoss, lots, magicNumber, error);
    }

    ticket = ticketNumber;
    return error;
}

static int OrderHelper::PlaceStopOrderForCandleBreak(double paddingPips, double spreadPips, double riskPercent, int magicNumber,
                                                     int type, string symbol, int timeFrame, int entryCandleIndex, int stopLossCandleIndex, int &ticketNumber)
{
    double entryPrice;
    double stopLoss;
    int orderType;

    if (type == OP_BUY)
    {
        orderType = OP_BUYSTOP;
        entryPrice = iHigh(symbol, timeFrame, entryCandleIndex) + PipsToRange(spreadPips);
        stopLoss = iLow(symbol, timeFrame, stopLossCandleIndex) - PipsToRange(paddingPips);
    }
    else if (type == OP_SELL)
    {
        // move the entry down 0.1 pips so that we only get entered if we actually break below and not if we just tap it
        orderType = OP_SELLSTOP;
        entryPrice = iLow(symbol, timeFrame, entryCandleIndex) - PipsToRange(0.1);
        stopLoss = iHigh(symbol, timeFrame, stopLossCandleIndex) + PipsToRange(spreadPips + paddingPips);
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int error = PlaceStopOrder(orderType, lots, entryPrice, stopLoss, 0, magicNumber, ticketNumber);

    return error;
}

static int OrderHelper::PlaceStopOrderForTheLittleDipper(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type, string symbol, int timeFrame,
                                                         int &ticketNumber)
{
    int orderType;
    double entryPrice;
    double stopLoss;

    if (type == OP_BUY)
    {
        orderType = OP_BUYSTOP;
        entryPrice = iHigh(symbol, timeFrame, 1) + OrderHelper::PipsToRange(spreadPips);
        stopLoss = iLow(symbol, timeFrame, 0) - OrderHelper::PipsToRange(paddingPips);
    }
    else if (type == OP_SELL)
    {
        orderType = OP_SELLSTOP;
        entryPrice = iLow(symbol, timeFrame, 1);
        stopLoss = iHigh(symbol, timeFrame, 0) + OrderHelper::PipsToRange(spreadPips + paddingPips);
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    return PlaceStopOrder(orderType, lots, entryPrice, stopLoss, 0, magicNumber, ticketNumber);
}
/*

   ____  _            _               ____  _                 ___          _                               __  __ ____
  |  _ \| | __ _  ___(_)_ __   __ _  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___    ___  _ __   |  \/  | __ ) ___
  | |_) | |/ _` |/ __| | '_ \ / _` | \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|  / _ \| '_ \  | |\/| |  _ \/ __|
  |  __/| | (_| | (__| | | | | (_| |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \ | (_) | | | | | |  | | |_) \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/  \___/|_| |_| |_|  |_|____/|___/
                              |___/                 |_|

*/
int OrderHelper::PlaceStopOrderForPendingMBValidation(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int setupMBNumber,
                                                      MBTracker *&mbt, out int &ticket)
{
    MBState *tempMBState;
    if (!mbt.MBIsMostRecent(setupMBNumber, tempMBState))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    int type = tempMBState.Type() + 4;
    double entryPrice = 0.0;
    int entryPriceError = GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, tempMBState.Type(), mbt, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    double stopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, tempMBState.Type(), mbt, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int error = PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber, ticket);
    if (error != ERR_NO_ERROR)
    {
        SendMBFailedOrderEmail(error, mbt);
    }

    return error;
}

int OrderHelper::PlaceStopOrderForBreakOfMB(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int mbNumber, MBTracker *&mbt, out int &ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
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

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int error = PlaceStopOrder(type, lots, entryPrice, stopLoss, 0, magicNumber, ticket);
    if (error != ERR_NO_ERROR)
    {
        SendMBFailedOrderEmail(error, mbt);
    }

    return error;
}

static int OrderHelper::PlaceStopOrderForPendingLiquidationSetupValidation(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int liquidationMBNumber,
                                                                           MBTracker *&mbt, out int &ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(liquidationMBNumber, tempMBState))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    int orderType = EMPTY;
    double entryPrice = 0.0;
    double stopLoss = 0.0;

    if (tempMBState.Type() == OP_BUY)
    {
        orderType = OP_SELLSTOP;
        entryPrice = iLow(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex());

        if (!MQLHelper::GetHighestHighBetween(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex(), 0, false, stopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss += PipsToRange(spreadPips + paddingPips);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        orderType = OP_BUYSTOP;
        entryPrice = iHigh(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex()) + PipsToRange(spreadPips);

        if (!MQLHelper::GetLowestLowBetween(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex(), 0, false, stopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        stopLoss -= PipsToRange(paddingPips);
    }

    double lots = GetLotSize(RangeToPips(MathAbs(entryPrice - stopLoss)), riskPercent);
    int error = PlaceStopOrder(orderType, lots, entryPrice, stopLoss, 0, magicNumber, ticket);
    if (error != ERR_NO_ERROR)
    {
        SendMBFailedOrderEmail(error, mbt);
    }

    return error;
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
static int OrderHelper::PartialTicket(int ticketNumber, double price, double lotsToPartial)
{
    GetLastError();
    if (!OrderClose(ticketNumber, lotsToPartial, price, 0, clrNONE))
    {
        int error = GetLastError();
        SendMail("Failed To Partial",
                 "Time: " + TimeToString(TimeCurrent()) + "\n" +
                     "Error: " + IntegerToString(error) + "\n" +
                     "Ticket Number: " + IntegerToString(ticketNumber) + "\n" +
                     "Price: " + DoubleToString(price, Digits) + "\n" +
                     "Bid: " + DoubleToString(Bid, Digits) + "\n" +
                     "Ask: " + DoubleToString(Ask, Digits) + "\n" +
                     "Current Lots: " + DoubleToString(OrderLots(), 2) + "\n" +
                     "New Lots: " + DoubleToString(lotsToPartial, 2));
        return error;
    }

    return ERR_NO_ERROR;
}

static int OrderHelper::MoveTicketToBreakEven(Ticket &ticket, double additionalPips = 0.0)
{
    bool selectError = ticket.SelectIfOpen("Checking To Edit Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    int type = OrderType();
    if (type >= 2)
    {
        return ERR_NO_ERROR;
    }

    double currentPrice;
    MqlTick currentTick;
    if (!SymbolInfoTick(_Symbol, currentTick))
    {
        return GetLastError();
    }

    double additionalRange = PipsToRange(additionalPips);
    double newPrice = 0.0;
    if (type == OP_BUY)
    {
        newPrice = OrderOpenPrice() + additionalRange;
        if (newPrice > currentTick.bid)
        {
            return ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
        }
    }
    else if (type == OP_SELL)
    {
        newPrice = OrderOpenPrice() - additionalRange;
        if (newPrice < currentTick.ask)
        {
            return ExecutionErrors::ORDER_ENTRY_FURTHER_THEN_PRICE;
        }
    }

    int error = ERR_NO_ERROR;
    if (!OrderModify(OrderTicket(), OrderOpenPrice(), newPrice, OrderTakeProfit(), OrderExpiration(), clrGreen))
    {
        error = GetLastError();
        SendMail("Failed to move to break even",
                 "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     "Type: " + IntegerToString(OrderType()) + "\n" +
                     "Ask: " + DoubleToString(Ask) + "\n" +
                     "Bid: " + DoubleToString(Bid) + "\n" +
                     "Entry: " + DoubleToString(OrderOpenPrice()) + "\n" +
                     "Current Stop Loss: " + DoubleToString(OrderStopLoss()) + "\n" +
                     "Error: " + IntegerToString(error));
    }

    return error;
}

static int OrderHelper::MoveToBreakEvenWithCandleFurtherThanEntry(string symbol, int timeFrame, bool waitForCandleClose, Ticket *&ticket)
{
    bool selectError = ticket.SelectIfOpen("Checking To Edit Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    int type = OrderType();
    if (type >= 2)
    {
        return ERR_NO_ERROR;
    }

    int index = waitForCandleClose ? 1 : 0;
    bool furtherThanEntry = false;

    if (type == OP_BUY)
    {
        furtherThanEntry = iLow(symbol, timeFrame, index) > OrderOpenPrice();
    }
    else if (type == OP_SELL)
    {
        furtherThanEntry = iHigh(symbol, timeFrame, index) < OrderOpenPrice();
    }

    if (!furtherThanEntry)
    {
        return ERR_NO_ERROR;
    }

    int error = ERR_NO_ERROR;
    if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration(), clrGreen))
    {
        Print("Time: ", Hour(), ":", Minute(), ":", Seconds(), ", Type: ", type, ", Entry: ", OrderOpenPrice(), ", Current SL: ", OrderStopLoss(), ", High: ", iHigh(symbol, timeFrame, 1), ", Low: ", iLow(symbol, timeFrame, 1));
        error = GetLastError();
        SendMail("Failed to move to break even",
                 "Time: " + IntegerToString(Hour()) + ":" + IntegerToString(Minute()) + ":" + IntegerToString(Seconds()) + "\n" +
                     "Magic Number: " + IntegerToString(OrderMagicNumber()) + "\n" +
                     "Type: " + IntegerToString(OrderType()) + "\n" +
                     "Ask: " + DoubleToString(Ask) + "\n" +
                     "Bid: " + DoubleToString(Bid) + "\n" +
                     "Entry: " + DoubleToString(OrderOpenPrice()) + "\n" +
                     "Current Stop Loss: " + DoubleToString(OrderStopLoss()) + "\n" +
                     "Error: " + IntegerToString(error));
    }

    return error;
}

static int OrderHelper::CheckEditStopLossForTheLittleDipper(double stopLossPaddingPips, double spreadPips, string symbol, int timeFrame, Ticket &ticket)
{
    int selectError = ticket.SelectIfOpen("Editing The Little Dipper Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    double newStopLoss = 0.0;
    if (OrderType() == OP_BUYSTOP)
    {
        double low = iLow(symbol, timeFrame, 0);
        if (low < OrderStopLoss())
        {
            newStopLoss = low - OrderHelper::PipsToRange(stopLossPaddingPips);
        }
    }
    else if (OrderType() == OP_SELLSTOP)
    {
        double high = iHigh(symbol, timeFrame, 0);
        if (high > OrderStopLoss())
        {
            newStopLoss = high + OrderHelper::PipsToRange(stopLossPaddingPips + spreadPips);
        }
    }

    if (newStopLoss != 0.0)
    {
        if (!OrderModify(ticket.Number(), OrderOpenPrice(), newStopLoss, 0, 0, clrNONE))
        {
            return GetLastError();
        }
    }

    return ERR_NO_ERROR;
}

/*

   _____    _ _ _   _                ___          _                 _____            __  __ ____    ____  _                 ___          _
  | ____|__| (_) |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___  |  ___|__  _ __  |  \/  | __ )  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___
  |  _| / _` | | __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __| | |_ / _ \| '__| | |\/| |  _ \  \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \ |  _| (_) | |    | |  | | |_) |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \
  |_____\__,_|_|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/ |_|  \___/|_|    |_|  |_|____/  |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/
                            |___/                                                                                 |_|

*/
static int OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(double paddingPips, double spreadPips, double riskPercent, int setupMBNumber,
                                                                 MBTracker *&mbt, out Ticket *&ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(setupMBNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    double newStopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, tempMBState.Type(), mbt, newStopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    bool selectError = ticket.SelectIfOpen("Checking To Edit Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    if (OrderType() < 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if (OrderStopLoss() == newStopLoss)
    {
        return ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
    }

    int type = OrderType();
    double entryPrice = OrderOpenPrice();
    double takeProfit = OrderTakeProfit();
    int magicNumber = OrderMagicNumber();
    datetime expiration = OrderExpiration();

    int closeError = ticket.Close();
    if (closeError != ERR_NO_ERROR)
    {
        return closeError;
    }

    double newLots = GetLotSize(RangeToPips(MathAbs(entryPrice - newStopLoss)), riskPercent);
    int newTicket;
    int placeOrderError = PlaceStopOrder(type, newLots, entryPrice, newStopLoss, takeProfit, magicNumber, newTicket);
    if (newTicket == EMPTY)
    {
        SendMBFailedOrderEmail(placeOrderError, mbt);
        return placeOrderError;
    }

    ticket.UpdateTicketNumber(newTicket);
    return ERR_NO_ERROR;
}

static int OrderHelper::CheckEditStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, double riskPercent,
                                                                 int mbNumber, MBTracker *&mbt, out Ticket *&ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    double newStopLoss = 0.0;
    int stopLossError = GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, mbNumber, mbt, newStopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    bool selectError = ticket.SelectIfOpen("Checking To Edit Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    if (OrderType() < 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if (OrderStopLoss() == newStopLoss)
    {
        return ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
    }

    int type = OrderType();
    double entryPrice = OrderOpenPrice();
    double takeProfit = OrderTakeProfit();
    int magicNumber = OrderMagicNumber();
    datetime expiration = OrderExpiration();

    int closeError = ticket.Close();
    if (closeError != ERR_NO_ERROR)
    {
        return closeError;
    }

    double newLots = GetLotSize(RangeToPips(MathAbs(entryPrice - newStopLoss)), riskPercent);
    int newTicket;
    int placeOrderError = PlaceStopOrder(type, newLots, entryPrice, newStopLoss, takeProfit, magicNumber, newTicket);
    if (newTicket == EMPTY)
    {
        SendMBFailedOrderEmail(placeOrderError, mbt);
        return placeOrderError;
    }

    ticket.UpdateTicketNumber(newTicket);
    return ERR_NO_ERROR;
}

static int OrderHelper::CheckEditStopLossForLiquidationMBSetup(double paddingPips, double spreadPips, double riskPercent,
                                                               int liquidationMBNumber, MBTracker *&mbt, out Ticket *&ticket)
{
    MBState *tempMBState;
    if (!mbt.GetMB(liquidationMBNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    double newStopLoss = 0.0;
    if (tempMBState.Type() == OP_BUY)
    {
        if (!MQLHelper::GetHighestHighBetween(mbt.Symbol(), mbt.TimeFrame(), tempMBState.LowIndex(), 0, false, newStopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        newStopLoss += PipsToRange(spreadPips + paddingPips);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        if (!MQLHelper::GetLowestLowBetween(mbt.Symbol(), mbt.TimeFrame(), tempMBState.HighIndex(), 0, false, newStopLoss))
        {
            return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
        }

        newStopLoss -= PipsToRange(paddingPips);
    }

    bool selectError = ticket.SelectIfOpen("Checking To Edit Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    if (OrderType() < 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    if (OrderStopLoss() == newStopLoss)
    {
        return ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
    }

    int type = OrderType();
    double entryPrice = OrderOpenPrice();
    double takeProfit = OrderTakeProfit();
    int magicNumber = OrderMagicNumber();
    datetime expiration = OrderExpiration();

    int closeError = ticket.Close();
    if (closeError != ERR_NO_ERROR)
    {
        return closeError;
    }

    double newLots = GetLotSize(RangeToPips(MathAbs(entryPrice - newStopLoss)), riskPercent);
    int newTicket;
    int placeOrderError = PlaceStopOrder(type, newLots, entryPrice, newStopLoss, takeProfit, magicNumber, newTicket);
    if (newTicket == EMPTY)
    {
        SendMBFailedOrderEmail(placeOrderError, mbt);
        return placeOrderError;
    }

    ticket.UpdateTicketNumber(newTicket);
    return ERR_NO_ERROR;
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
static int OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker *&mbt,
                                                              Ticket *&ticket, out bool &succeeded)
{
    succeeded = false;

    int selectError = ticket.SelectIfOpen("Checking To Trail Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    if (OrderType() >= 2)
    {
        return TerminalErrors::WRONG_ORDER_TYPE;
    }

    MBState *tempMBState;
    if (!mbt.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Number() <= setUpMB)
    {
        return ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != setUpType)
    {
        return ExecutionErrors::NOT_EQUAL_MB_TYPES;
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
        return ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD;
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
        SendMBFailedOrderEmail(error, mbt);
    }

    succeeded = true;
    return error;
}
