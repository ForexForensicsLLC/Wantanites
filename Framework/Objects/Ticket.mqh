//+------------------------------------------------------------------+
//|                                                       Ticket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\TerminalErrors.mqh>

#include <SummitCapital\Framework\Objects\List.mqh>
#include <SummitCapital\Framework\Objects\PartialList.mqh>

class Ticket
{
private:
    int mNumber;

    bool mIsClosed;
    bool mIsActive;
    bool mStopLossIsMovedToBreakEven;

    int SelectTicket(string action);
    int InternalCheckActive(bool &active);
    int InternalCheckClosed(bool &closed);

public:
    Ticket();
    Ticket(int ticket);
    Ticket(Ticket &ticket);
    ~Ticket();

    void SetNewTicket(int ticket);
    void UpdateTicketNumber(int newTicketNumber);

    PartialList *mPartials;
    double mRRAcquired;
    int Number() { return mNumber; }

    // Tested
    int WasActivated(bool &active);

    // Tested
    int IsActive(bool &active);

    // Tested
    int WasClosed(bool &closed);

    // Tested
    int IsClosed(bool &closed);

    int Close();

    int SelectIfOpen(string action);
    int SelectIfClosed(string action);

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);

    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);
};

Ticket::Ticket()
{
    SetNewTicket(EMPTY);
}

Ticket::Ticket(int ticket)
{
    SetNewTicket(ticket);
}

Ticket::Ticket(Ticket &ticket)
{
    mNumber = ticket.Number();
    mRRAcquired = ticket.mRRAcquired;
    mPartials = new PartialList(ticket.mPartials);

    ticket.IsActive(mIsActive);
    ticket.IsClosed(mIsClosed);
    ticket.StopLossIsMovedToBreakEven(mStopLossIsMovedToBreakEven);
}

Ticket::~Ticket()
{
}

void Ticket::SetNewTicket(int ticket)
{
    mNumber = ticket;
    mRRAcquired = 0;
    mPartials.Clear();

    mIsActive = false;
    mIsClosed = false;
    mStopLossIsMovedToBreakEven = false;
}

void Ticket::UpdateTicketNumber(int newTicketNumber)
{
    mNumber = newTicketNumber;
}

int Ticket::SelectTicket(string action)
{
    if (!OrderSelect(mNumber, SELECT_BY_TICKET))
    {
        bool found = false;
        for (int i = 0; i < OrdersTotal(); i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS))
            {
                int error = GetLastError();
                SendMail("Failed To Select Order By Ticket When " + action,
                         "Total Orders: " + IntegerToString(OrdersTotal()) + "\n" +
                             "Current Index: " + IntegerToString(i) + "\n" +
                             "Current Ticket: " + IntegerToString(mNumber) + "\n" +
                             IntegerToString(error));

                return error;
            }

            if (OrderTicket() == mNumber)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            return TerminalErrors::ORDER_NOT_FOUND;
        }
    }

    return ERR_NO_ERROR;
}

int Ticket::SelectIfOpen(string action)
{
    int selectOrderError = SelectTicket(action);
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    if (OrderCloseTime() != 0)
    {
        return TerminalErrors::ORDER_IS_CLOSED;
    }

    return ERR_NO_ERROR;
}

int Ticket::SelectIfClosed(string action)
{
    int selectOrderError = SelectTicket(action);
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    if (OrderCloseTime() == 0)
    {
        return TerminalErrors::ORDER_IS_OPEN;
    }

    return ERR_NO_ERROR;
}

int Ticket::InternalCheckActive(bool &isActive)
{
    int selectTicketError = SelectIfOpen("Checking if Active");
    if (selectTicketError != ERR_NO_ERROR)
    {
        isActive = false;
        return selectTicketError;
    }

    if (OrderType() >= 2)
    {
        isActive = false;
        return ERR_NO_ERROR;
    }

    mIsActive = true;
    isActive = mIsActive;

    return ERR_NO_ERROR;
}

int Ticket::InternalCheckClosed(bool &closed)
{
    int selectTicketError = SelectIfClosed("Checking if Closed");
    if (selectTicketError != ERR_NO_ERROR)
    {
        closed = false;
        return ERR_NO_ERROR;
    }

    mIsClosed = true;
    closed = mIsClosed;

    return ERR_NO_ERROR;
}

/**
 * @brief Checks if an order was activated from the last check
 *
 * @param activated
 * @return int
 */
int Ticket::WasActivated(bool &activated)
{
    if (mIsActive)
    {
        activated = false;
        return ERR_NO_ERROR;
    }

    return InternalCheckActive(activated);
}

/**
 * @brief Checks if an orders is active
 *
 * @param active
 * @return int
 */
int Ticket::IsActive(bool &active)
{
    if (mIsActive)
    {
        active = true;
        return ERR_NO_ERROR;
    }

    return InternalCheckActive(active);
}

/**
 * @brief Checks if an order has been closed from the last check
 *
 * @param closed
 * @return int
 */
int Ticket::WasClosed(bool &closed)
{
    if (mIsClosed)
    {
        closed = false;
        return ERR_NO_ERROR;
    }

    return InternalCheckClosed(closed);
}

/**
 * @brief Checks if an order is closed
 *
 * @param closed
 * @return int
 */
int Ticket::IsClosed(bool &closed)
{
    if (mIsClosed)
    {
        closed = true;
        return ERR_NO_ERROR;
    }

    return InternalCheckClosed(closed);
}

int Ticket::Close()
{
    int selectOrderError = SelectIfOpen("Closing");
    if (selectOrderError != ERR_NO_ERROR)
    {
        return selectOrderError;
    }

    if (OrderType() > 1)
    {
        if (!OrderDelete(mNumber, clrNONE))
        {
            return GetLastError();
        }
    }
    else
    {
        double closeAt = OrderType() == OP_BUY ? Bid : Ask;
        if (!OrderClose(mNumber, OrderLots(), closeAt, 0, clrNONE))
        {
            return GetLastError();
        }
    }

    return ERR_NO_ERROR;
}

int Ticket::StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven)
{
    if (!mStopLossIsMovedToBreakEven)
    {
        int error = SelectIfOpen("Checking If Break Even");
        if (error != ERR_NO_ERROR)
        {
            return error;
        }

        mStopLossIsMovedToBreakEven = OrderOpenPrice() == OrderStopLoss();
    }

    stopLossIsMovedBreakEven = mStopLossIsMovedToBreakEven;
    return ERR_NO_ERROR;
}

void Ticket::SetPartials(List<double> &partialRRs, List<double> &partialPercents)
{
    for (int i = 0; i < partialRRs.Size(); i++)
    {
        Partial *partial = new Partial(partialRRs[i], partialPercents[i]);
        mPartials.Add(partial);
    }
}