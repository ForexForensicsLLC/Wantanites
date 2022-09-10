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

    bool mLastCloseCheck;
    bool mLastActiveCheck;

    bool mIsClosed;
    bool mIsActive;

    bool mStopLossIsMovedToBreakEven;

    double mOpenPrice;
    datetime mOpenTime;
    double mLots;

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
    double mOriginalStopLoss;

    int Number() { return mNumber; }

    double OpenPrice();
    void OpenPrice(double openPrice) { mOpenPrice = openPrice; }

    datetime OpenTime();
    void OpenTime(datetime openTime) { mOpenTime = openTime; }

    double Lots();
    void Lots(double lots) { mLots = lots; }

    int WasActivatedSinceLastCheck(bool &active); // Tested
    int IsActive(bool &active);                   // Tested
    int WasClosedSinceLastCheck(bool &closed);    // Tested
    int IsClosed(bool &closed);                   // Tested

    int Close();

    int SelectIfOpen(string action);
    int SelectIfClosed(string action);

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);

    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);
};

Ticket::Ticket()
{
    mPartials = new PartialList();
    SetNewTicket(EMPTY);
}

Ticket::Ticket(int ticket)
{
    mPartials = new PartialList();
    SetNewTicket(ticket);
}

Ticket::Ticket(Ticket &ticket)
{
    mNumber = ticket.Number();
    mRRAcquired = ticket.mRRAcquired;
    mPartials = new PartialList(ticket.mPartials);

    mOpenPrice = ticket.OpenPrice();
    mOpenTime = ticket.OpenTime();
    mOriginalStopLoss = ticket.mOriginalStopLoss;
    mLots = ticket.Lots();

    ticket.IsActive(mIsActive);
    ticket.IsClosed(mIsClosed);
    ticket.StopLossIsMovedToBreakEven(mStopLossIsMovedToBreakEven);
}

Ticket::~Ticket()
{
    delete mPartials;
}

void Ticket::SetNewTicket(int ticket)
{
    mNumber = ticket;

    mLastCloseCheck = false;
    mLastActiveCheck = false;

    mIsActive = false;
    mIsClosed = false;

    mRRAcquired = 0;
    mStopLossIsMovedToBreakEven = false;

    mOpenPrice = 0.0;
    mOpenTime = 0;
    mOriginalStopLoss = 0.0;
    mLots = 0.0;

    mPartials.Clear();
}

double Ticket::OpenPrice()
{
    if (mOpenPrice != 0.0)
    {
        return mOpenPrice;
    }

    int selectError = SelectIfOpen("Retrieving Open Price");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Price",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0.0;
    }

    mOpenPrice = OrderOpenPrice();
    return mOpenPrice;
}

datetime Ticket::OpenTime()
{
    if (mOpenTime != 0)
    {
        return mOpenTime;
    }

    int selectError = SelectIfOpen("Retrieving Open Time");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Open Time",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mOpenTime = OrderOpenTime();
    return mOpenTime;
}

double Ticket::Lots()
{
    if (mLots != 0.0)
    {
        return mLots;
    }

    int selectError = SelectIfOpen("Retrieving Lots");
    if (selectError != ERR_NO_ERROR)
    {
        SendMail("Unable To Retrieve Lots",
                 "Error: " + IntegerToString(selectError) + "\n" +
                     "Ticket Number: " + IntegerToString(mNumber));

        return 0;
    }

    mLots = OrderLots();
    return mLots;
}

void Ticket::UpdateTicketNumber(int newTicketNumber)
{
    mNumber = newTicketNumber;
    mIsClosed = false;
    mIsActive = false;
    mStopLossIsMovedToBreakEven = false;
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
int Ticket::WasActivatedSinceLastCheck(bool &activated)
{
    if (mIsActive)
    {
        activated = !mLastActiveCheck;
        mLastActiveCheck = true;

        return ERR_NO_ERROR;
    }

    int error = InternalCheckActive(mLastActiveCheck);

    activated = mLastActiveCheck;
    return error;
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
int Ticket::WasClosedSinceLastCheck(bool &closed)
{
    if (mIsClosed)
    {
        closed = !mLastCloseCheck;
        mLastCloseCheck = true;

        return ERR_NO_ERROR;
    }

    int error = InternalCheckClosed(mLastCloseCheck);
    closed = mLastCloseCheck;

    return error;
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