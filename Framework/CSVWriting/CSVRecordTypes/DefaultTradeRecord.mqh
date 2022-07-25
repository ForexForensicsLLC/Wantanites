//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\ICSVRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class DefaultTradeRecord : ICSVRecord
{
protected:
    string mSymbol;
    int mTimeFrame;
    string mOrderType;
    double mAccountBalanceBefore;
    double mAccountBalanceAfter;
    datetime mEntryTime;
    string mEntryImage;
    datetime mExitTime;
    string mExitImage;
    double mEntryPrice;
    double mEntryStopLoss;
    double mLots;
    double mExitPrice;
    double mExitStopLoss;

public:
    void Symbol(string symbol) { mSymbol = symbol; }
    void TimeFrame(int timeFrame) { mTimeFrame = timeFrame; }
    void OrderType(string orderType) { mOrderType = orderType; }
    void AccountBalanceBefore(double accountBalanceBefore) { mAccountBalanceBefore = accountBalanceBefore; }
    void AccountBalanceAfter(double accountBalanceAfter) { mAccountBalanceAfter = accountBalanceAfter; }
    void EntryTime(datetime entryTime) { mEntryTime = entryTime; }
    void EntryImage(string entryImage) { mEntryImage = entryImage; }
    void ExitTime(datetime exitTime) { mExitTime = exitTime; }
    void ExitImage(string exitImage) { mExitImage = exitImage; }
    void EntryPrice(double entryPrice) { mEntryPrice = entryPrice; }
    void EntryStopLoss(double entryStopLoss) { mEntryStopLoss = entryStopLoss; }
    void Lots(double lots) { mLots = lots; }
    void ExitPrice(double exitPrice) { mExitPrice = exitPrice; }
    void ExitStopLoss(double exitStopLoss) { mExitStopLoss = exitStopLoss; }

    DefaultTradeRecord();
    ~DefaultTradeRecord();

    double TotalMovePips() { return NormalizeDouble(OrderHelper::RangeToPips((mEntryPrice - mExitPrice)), 2); }
    double PotentialRR() { return NormalizeDouble((mEntryPrice - mExitPrice) / (mEntryPrice - mEntryStopLoss), 2); }

    void Write(int fileHandle);
};

void DefaultTradeRecord::Write(int fileHandle)
{
    FileWrite(fileHandle, mSymbol, mTimeFrame, mOrderType, mAccountBalanceBefore, mAccountBalanceAfter, mEntryTime, mEntryImage, mExitTime, mExitImage, mEntryPrice,
              mEntryStopLoss, mLots, mExitPrice, mExitStopLoss, TotalMovePips(), PotentialRR());
}
