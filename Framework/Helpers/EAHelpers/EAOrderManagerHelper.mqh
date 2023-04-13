//+------------------------------------------------------------------+
//|                                                     EAOrderManagerHelper.mqh |
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

class EAOrderManagerHelper
{
    template <typename TEA>
    static void MoveTicketToBreakEven(TEA &ea, Ticket &ticket, double additionalPips);
};

template <typename TEA>
static void EAOrderManagerHelper::MoveTicketToBreakEven(TEA &ea, Ticket &ticket, double additionalPips = 0.0)
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