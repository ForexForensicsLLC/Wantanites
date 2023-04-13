//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\Ticket.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\MBTracker.mqh>
#include <Wantanites\Framework\Constants\Index.mqh>

class OrderHelper
{
public:
    // =========================================================================
    // Placing Market Orders
    // =========================================================================
    static int PlaceMarketOrderForCandleSetup(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type,
                                              string symbol, int timeFrame, int stopLossCandleIndex, int &ticketNumber);

    // ==========================================================================
    // Placing Stop Orders
    // ==========================================================================
    static int PlaceStopOrderForCandleBreak(double paddingPips, double spreadPips, double riskPercent, int magicNumber,
                                            int type, string symbol, int timeFrame, int entryCandleIndex, int stopLossCandleIndex, int &ticketNumber);
    static int PlaceStopOrderForTheLittleDipper(double paddingPips, double spreadPips, double riskPercent, int magicNumber, int type, string symbol, int timeFrame,
                                                int &ticketNumber);

    // ==========================================================================
    // Editing Orders
    // ==========================================================================
    static int MoveToBreakEvenWithCandleFurtherThanEntry(string symbol, int timeFrame, bool waitForCandleClose, Ticket *&ticket);
    static int CheckEditStopLossForTheLittleDipper(double stopLossPaddingPips, double spreadPips, string symbol, int timeFrame, Ticket &ticket);

    // ==========================================================================
    // Editing Orders For MB Stop Orders
    // ==========================================================================
    static int CheckEditStopLossForStopOrderOnPendingMB(double paddingPips, double spreadPips, double riskPercent,
                                                        int setupMBNumber, MBTracker *&mbt, out Ticket *&ticket);
    static int CheckEditStopLossForStopOrderOnBreakOfMB(double paddingPips, double spreadPips, double riskPercent,
                                                        int mbNumber, MBTracker *&mbt, out Ticket *&ticket);

    static int CheckEditStopLossForLiquidationMBSetup(double paddingPips, double spreadPips, double riskPercent,
                                                      int liquidationMBNumber, MBTracker *&mbt, out Ticket *&ticket);

    // ==========================================================================
    // Moving To Break Even By MB
    // ==========================================================================
    static int CheckTrailStopLossWithMBUpToBreakEven(double paddingPips, double spreadPips, int setUpMB, int setUpType, MBTracker *&mbt, Ticket *&ticket, out bool &succeeded);
};

/*

   ____  _            _               __  __            _        _      ___          _
  |  _ \| | __ _  ___(_)_ __   __ _  |  \/  | __ _ _ __| | _____| |_   / _ \ _ __ __| | ___ _ __ ___
  | |_) | |/ _` |/ __| | '_ \ / _` | | |\/| |/ _` | '__| |/ / _ \ __| | | | | '__/ _` |/ _ \ '__/ __|
  |  __/| | (_| | (__| | | | | (_| | | |  | | (_| | |  |   <  __/ |_  | |_| | | | (_| |  __/ |  \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |_|  |_|\__,_|_|  |_|\_\___|\__|  \___/|_|  \__,_|\___|_|  |___/
                              |___/

*/

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

/*

   ____  _            _               ____  _                 ___          _
  |  _ \| | __ _  ___(_)_ __   __ _  / ___|| |_ ___  _ __    / _ \ _ __ __| | ___ _ __ ___
  | |_) | |/ _` |/ __| | '_ \ / _` | \___ \| __/ _ \| '_ \  | | | | '__/ _` |/ _ \ '__/ __|
  |  __/| | (_| | (__| | | | | (_| |  ___) | || (_) | |_) | | |_| | | | (_| |  __/ |  \__ \
  |_|   |_|\__,_|\___|_|_| |_|\__, | |____/ \__\___/| .__/   \___/|_|  \__,_|\___|_|  |___/
                              |___/                 |_|
*/

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
/*

   _____    _ _ _   _                ___          _
  | ____|__| (_) |_(_)_ __   __ _   / _ \ _ __ __| | ___ _ __ ___
  |  _| / _` | | __| | '_ \ / _` | | | | | '__/ _` |/ _ \ '__/ __|
  | |__| (_| | | |_| | | | | (_| | | |_| | | | (_| |  __/ |  \__ \
  |_____\__,_|_|\__|_|_| |_|\__, |  \___/|_|  \__,_|\___|_|  |___/
                            |___/

*/
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
