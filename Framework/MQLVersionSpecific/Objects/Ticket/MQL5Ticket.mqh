//+------------------------------------------------------------------+
//|                                                       Ticket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\BaseTicket.mqh>

enum TicketStatus
{
    Pending,
    Active,
    ClosedPending,
    ClosedDeal
};

class Ticket : public BaseTicket
{
private:
    CTrade mTrade;
    TicketStatus mStatus;

protected:
    int SelectDeal(ENUM_DEAL_ENTRY dealType, ulong &dealTicket);
    virtual int SelectIfOpen(string action);

    int SelectIfClosed(string action, ulong &dealTicket);
    virtual int SelectIfClosed(string action);

public:
    Ticket();
    Ticket(int ticketNumber);
    Ticket(Ticket &ticket);

    TicketStatus Status() { return mStatus; }

    virtual int MagicNumber();
    virtual TicketType Type();
    virtual double OpenPrice();
    virtual datetime OpenTime();
    virtual double LotSize();
    virtual double CurrentStopLoss();
    virtual double ClosePrice();
    virtual datetime CloseTime();
    virtual double TakeProfit();
    virtual datetime Expiration();
    virtual double Profit();
    virtual double Commission();

    virtual int WasActivated(bool &wasActivated);

    virtual int Close();
    virtual int ClosePartial(double price, double lotSize);
};

Ticket::Ticket() : BaseTicket()
{
    mStatus = TicketStatus::Pending;
}

Ticket::Ticket(int ticketNumber) : BaseTicket(ticketNumber)
{
    mStatus = TicketStatus::Pending;
}

Ticket::Ticket(Ticket &ticket) : BaseTicket(ticket)
{
    mStatus = ticket.Status();
}

int Ticket::SelectDeal(ENUM_DEAL_ENTRY dealType, ulong &dealTicket)
{
    datetime currentTime = TimeCurrent();
    HistorySelect(currentTime - (60 * 60 * 24), currentTime);

    for (int i = 0; i < HistoryDealsTotal(); i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket <= 0)
        {
            continue;
        }

        ulong positionNumber = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
        if (positionNumber == mNumber && HistoryDealGetInteger(ticket, DEAL_ENTRY) == dealType)
        {
            HistoryDealSelect(ticket);
            dealTicket = ticket;

            return Errors::NO_ERROR;
        }
    }

    return Errors::ORDER_NOT_FOUND;
}

int Ticket::SelectIfOpen(string action)
{
    if (mStatus == TicketStatus::ClosedPending || mStatus == TicketStatus::ClosedDeal)
    {
        return Errors::ORDER_IS_CLOSED;
    }

    bool found = false;
    if (mStatus == TicketStatus::Pending)
    {
        found = OrderSelect(mNumber);
    }

    if (mStatus == TicketStatus::Active || !found)
    {
        if (PositionSelectByTicket(mNumber))
        {
            if (mStatus != TicketStatus::Active)
            {
                mStatus = TicketStatus::Active;
            }

            found = true;
        }
    }

    if (!found)
    {
        return Errors::ORDER_NOT_FOUND;
    }

    return Errors::NO_ERROR;
}

int Ticket::SelectIfClosed(string action, ulong &dealTicket)
{
    // need to first check if the ticket is still opened as History Orders will have our ticket even if it is a current position
    if ((mStatus != TicketStatus::ClosedPending && mStatus != TicketStatus::ClosedDeal) && SelectIfOpen("Selecting if closed") == Errors::NO_ERROR)
    {
        return Errors::ORDER_IS_OPEN;
    }

    if (SelectDeal(DEAL_ENTRY_OUT, dealTicket) == Errors::NO_ERROR)
    {
        if (mStatus != TicketStatus::ClosedDeal)
        {
            mStatus = TicketStatus::ClosedDeal;
        }
    }
    else if (HistoryOrderSelect(mNumber))
    {
        if (mStatus != TicketStatus::ClosedPending)
        {
            mStatus = TicketStatus::ClosedPending;
        }
    }
    else
    {
        return Errors::ORDER_NOT_FOUND;
    }

    return Errors::NO_ERROR;
}

int Ticket::SelectIfClosed(string action)
{
    ulong tempTicket = -1;
    return SelectIfClosed(action, tempTicket);
}

int Ticket::MagicNumber()
{
    if (mMagicNumber != ConstantValues::EmptyInt)
    {
        return mMagicNumber;
    }

    int openError = SelectIfOpen("Getting Magic Number");
    if (openError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            mMagicNumber = OrderGetInteger(ORDER_MAGIC);
        }
        else if (mStatus == TicketStatus::Active)
        {
            mMagicNumber = PositionGetInteger(POSITION_MAGIC);
        }
    }
    else
    {
        ulong dealTicket = ConstantValues::EmptyInt;
        int closedError = SelectIfClosed("Getting Magic Number", dealTicket);
        if (closedError != Errors::NO_ERROR)
        {
            return closedError;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            mMagicNumber = HistoryOrderGetInteger(mNumber, ORDER_MAGIC);
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            mMagicNumber = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
        }
    }

    return mMagicNumber;
}

TicketType Ticket::Type()
{
    if (mType != TicketType::Empty)
    {
        return mType;
    }

    int type = -1;
    int openError = SelectIfOpen("Getting type");
    if (openError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            type = OrderGetInteger(ORDER_TYPE);
            switch ((ENUM_ORDER_TYPE)type)
            {
            case ORDER_TYPE_BUY_LIMIT:
                return mType;
            case ORDER_TYPE_SELL_LIMIT:
                return mType;
            case ORDER_TYPE_BUY_STOP:
                return mType;
            case ORDER_TYPE_SELL_STOP:
                return mType;
            default:
                return TicketType::Empty;
            }
        }
        else if (mStatus == TicketStatus::Active)
        {
            type = PositionGetInteger(POSITION_TYPE);
            switch ((ENUM_POSITION_TYPE)type)
            {
            case POSITION_TYPE_BUY:
                mType = TicketType::Buy;
                return mType;
            case POSITION_TYPE_SELL:
                mType = TicketType::Sell;
                return mType;
            default:
                return TicketType::Empty;
            }
        }
    }
    else
    {
        ulong dealTicket = -1;
        int closedError = SelectIfClosed("Getting Type", dealTicket);
        if (closedError != Errors::NO_ERROR)
        {
            return closedError;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            type = HistoryOrderGetInteger(mNumber, ORDER_TYPE);
            switch ((ENUM_ORDER_TYPE)type)
            {
            case ORDER_TYPE_BUY_LIMIT:
                mType = TicketType::BuyLimit;
                return mType;
            case ORDER_TYPE_SELL_LIMIT:
                mType = TicketType::SellLimit;
                return mType;
            case ORDER_TYPE_BUY_STOP:
                mType = TicketType::BuyStop;
                return mType;
            case ORDER_TYPE_SELL_STOP:
                mType = TicketType::SellStop;
                return mType;
            default:
                return TicketType::Empty;
            }
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            type = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
            switch ((ENUM_DEAL_TYPE)type)
            {
            case DEAL_TYPE_BUY:
                mType = TicketType::Buy;
                return mType;
            case DEAL_TYPE_SELL:
                mType = TicketType::Sell;
                return mType;
            default:
                return TicketType::Empty;
            }
        }
    }

    return TicketType::Empty;
}

double Ticket::OpenPrice()
{
    if (mOpenPrice != ConstantValues::EmptyDouble)
    {
        return mOpenPrice;
    }

    ulong dealTicket;
    int dealSelectError = SelectDeal(DEAL_ENTRY_IN, dealTicket);
    if (dealSelectError != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    mOpenPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
    return mOpenPrice;
}

datetime Ticket::OpenTime()
{
    if (mOpenTime != 0)
    {
        return mOpenTime;
    }

    ulong dealTicket;
    int dealSelectError = SelectDeal(DEAL_ENTRY_IN, dealTicket);
    if (dealSelectError != Errors::NO_ERROR)
    {
        return 0;
    }

    mOpenTime = HistoryDealGetInteger(dealTicket, DEAL_TIME);
    return mOpenTime;
}

double Ticket::LotSize()
{
    if (mLotSize != ConstantValues::EmptyDouble)
    {
        return mLotSize;
    }

    ulong dealTicket;
    int dealSelectError = SelectDeal(DEAL_ENTRY_IN, dealTicket);
    if (dealSelectError != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    mLotSize = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
    return mLotSize;
}

double Ticket::CurrentStopLoss()
{
    if (mCurrentStopLoss != ConstantValues::EmptyDouble)
    {
        return mCurrentStopLoss;
    }

    int openError = SelectIfOpen("Getting SL");
    if (openError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            return OrderGetDouble(ORDER_SL);
        }
        else if (mStatus == TicketStatus::Active)
        {
            return PositionGetDouble(POSITION_SL);
        }
    }
    else
    {
        ulong dealTicket = ConstantValues::EmptyInt;
        int closedError = SelectIfClosed("Getting SL", dealTicket);
        if (closedError != Errors::NO_ERROR)
        {
            return closedError;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            mCurrentStopLoss = HistoryOrderGetDouble(mNumber, ORDER_SL);
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            mCurrentStopLoss = HistoryDealGetDouble(dealTicket, DEAL_SL);
        }
    }

    return mCurrentStopLoss;
}
double Ticket::ClosePrice()
{
    if (mClosePrice != ConstantValues::EmptyDouble)
    {
        return mClosePrice;
    }

    ulong dealTicket;
    int dealSelectError = SelectDeal(DEAL_ENTRY_OUT, dealTicket);
    if (dealSelectError != Errors::NO_ERROR)
    {
        return ConstantValues::EmptyDouble;
    }

    mClosePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
    return mClosePrice;
}

datetime Ticket::CloseTime()
{
    if (mCloseTime != 0)
    {
        return mCloseTime;
    }

    ulong dealTicket;
    int dealSelectError = SelectDeal(DEAL_ENTRY_OUT, dealTicket);
    if (dealSelectError != Errors::NO_ERROR)
    {
        return 0;
    }

    mCloseTime = HistoryDealGetInteger(dealTicket, DEAL_TIME);
    return mCloseTime;
}

double Ticket::TakeProfit()
{
    if (mTakeProfit != ConstantValues::EmptyDouble)
    {
        return mTakeProfit;
    }

    int openError = SelectIfOpen("Getting SL");
    if (openError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            return OrderGetDouble(ORDER_TP);
        }
        else if (mStatus == TicketStatus::Active)
        {
            return PositionGetDouble(POSITION_TP);
        }
    }
    else
    {
        ulong dealTicket = ConstantValues::EmptyInt;
        int closedError = SelectIfClosed("Getting SL", dealTicket);
        if (closedError != Errors::NO_ERROR)
        {
            return closedError;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            mTakeProfit = HistoryOrderGetDouble(mNumber, ORDER_TP);
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            mTakeProfit = HistoryDealGetDouble(dealTicket, DEAL_TP);
        }
    }

    return mTakeProfit;
}

datetime Ticket::Expiration()
{
    if (mExpiration != 0)
    {
        return mExpiration;
    }

    int openSelectError = SelectIfOpen("Getting Expiration");
    if (openSelectError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            mExpiration = OrderGetInteger(ORDER_TIME_EXPIRATION);
        }
        else if (mStatus == TicketStatus::Active)
        {
            return 0;
        }
    }
    else
    {
        int closedSelectError = SelectIfClosed("Getting Expiration");
        if (closedSelectError != Errors::NO_ERROR)
        {
            return 0;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            mExpiration = HistoryOrderGetInteger(mNumber, ORDER_TIME_EXPIRATION);
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            return 0;
        }
    }

    return mExpiration;
}

double Ticket::Profit()
{
    if (mProfit != ConstantValues::EmptyDouble)
    {
        return mProfit;
    }

    int openError = SelectIfOpen("Getting SL");
    if (openError == Errors::NO_ERROR)
    {
        if (mStatus == TicketStatus::Pending)
        {
            return ConstantValues::EmptyDouble;
        }
        else if (mStatus == TicketStatus::Active)
        {
            return PositionGetDouble(POSITION_PROFIT);
        }
    }
    else
    {
        ulong dealTicket = ConstantValues::EmptyInt;
        int closedError = SelectIfClosed("Getting SL", dealTicket);
        if (closedError != Errors::NO_ERROR)
        {
            return closedError;
        }

        if (mStatus == TicketStatus::ClosedPending)
        {
            return ConstantValues::EmptyDouble;
        }
        else if (mStatus == TicketStatus::ClosedDeal)
        {
            mProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        }
    }

    return mProfit;
}

double Ticket::Commission()
{
    if (mCommission != ConstantValues::EmptyDouble)
    {
        return mCommission;
    }

    ulong dealTicket;
    double commissions = 0.0;

    int dealSelectErrorOne = SelectDeal(DEAL_ENTRY_IN, dealTicket);
    if (dealSelectErrorOne != Errors::NO_ERROR)
    {
        return 0;
    }

    commissions += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

    int dealSelectErrorTwo = SelectDeal(DEAL_ENTRY_OUT, dealTicket);
    if (dealSelectErrorTwo != Errors::NO_ERROR)
    {
        return commissions;
    }

    commissions += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
    mCommission = commissions;

    return mCommission;
}

int Ticket::WasActivated(bool &wasActivated)
{
    if (mWasActivated)
    {
        wasActivated = mWasActivated;
        return Errors::NO_ERROR;
    }

    ulong tempDealTicket = -1;
    int selectDealError = SelectDeal(DEAL_ENTRY_IN, tempDealTicket);
    if (selectDealError != Errors::NO_ERROR)
    {
        wasActivated = false;
        return selectDealError;
    }

    mWasActivated = true;
    wasActivated = mWasActivated;

    return Errors::NO_ERROR;
}

int Ticket::Close()
{
    int openSelectError = SelectIfOpen("Closing");
    if (openSelectError != Errors::NO_ERROR)
    {
        return openSelectError;
    }

    MqlTick currentTick;
    SymbolInfoTick(Symbol(), currentTick);
    int freezeLevel = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_FREEZE_LEVEL);

    double sl = CurrentStopLoss();
    if (sl != ConstantValues::EmptyDouble)
    {
        double marketPrice = ConstantValues::EmptyDouble;
        if (sl < OpenPrice())
        {
            marketPrice = currentTick.bid;
        }
        else
        {
            marketPrice = currentTick.ask;
        }

        if (MathAbs(marketPrice - sl) <= freezeLevel * _Point)
        {
            return Errors::MARKET_TOO_CLOSE_TO_SL;
        }
    }

    if (mStatus == TicketStatus::Pending)
    {
        if (!mTrade.OrderDelete(mNumber))
        {
            return GetLastError();
        }
    }
    else if (mStatus == TicketStatus::Active)
    {
        if (!mTrade.PositionClose(mNumber))
        {
            return GetLastError();
        }
    }

    mWasManuallyClosed = true;
    return Errors::NO_ERROR;
}

int Ticket::ClosePartial(double price, double lotSize)
{
    int openSelectError = SelectIfOpen("Closing");
    if (openSelectError != Errors::NO_ERROR)
    {
        return openSelectError;
    }

    if (mStatus != TicketStatus::Active)
    {
        return Errors::WRONG_ORDER_TYPE;
    }

    if (!mTrade.PositionClosePartial(mNumber, lotSize))
    {
        return GetLastError();
    }

    return Errors::NO_ERROR;
}
