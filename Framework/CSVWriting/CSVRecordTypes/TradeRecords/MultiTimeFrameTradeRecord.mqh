//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\DefaultTradeRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class MultiTimeFrameTradeRecord : public DefaultTradeRecord
{
public:
    string HigherTimeFrameEntryImage;
    string LowerTimeFrameEntryImage;

    string HigherTimeFrameExitImage;
    string LowerTimeFrameExitImage;

    MultiTimeFrameTradeRecord();
    ~MultiTimeFrameTradeRecord();

    virtual void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
    virtual void Reset();
};

MultiTimeFrameTradeRecord::MultiTimeFrameTradeRecord()
{
    Reset();
}

MultiTimeFrameTradeRecord::~MultiTimeFrameTradeRecord() {}

void MultiTimeFrameTradeRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle,
              "Symbol",
              "Order Type",
              "Account Balance Before",
              "Account Balance After",
              "Lots",
              "Entry Time",
              "Entry Price",
              "Entry Stop Loss",
              "Higher Time Frame Entry Image",
              "Lower Time Frame Exit Image",
              "Exit Time",
              "Exit Price",
              "Exit Stop Loss",
              "Higher Time Frame Entry Image",
              "Lower Time Frame Exit Image",
              "Total Move Pips",
              "Potential RR",
              "Last State",
              "Error",
              "Error Image",
              "Notes");
}

void MultiTimeFrameTradeRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle,
              Symbol,
              OrderType,
              AccountBalanceBefore,
              AccountBalanceAfter,
              Lots,
              EntryTime,
              EntryPrice,
              EntryStopLoss,
              HigherTimeFrameEntryImage,
              LowerTimeFrameEntryImage,
              ExitTime,
              ExitPrice,
              ExitStopLoss,
              HigherTimeFrameExitImage,
              LowerTimeFrameExitImage,
              TotalMovePips(),
              PotentialRR(),
              LastState,
              Error,
              ErrorImage,
              Notes);
}

void MultiTimeFrameTradeRecord::Reset()
{
    HigherTimeFrameEntryImage = "";
    LowerTimeFrameEntryImage = "";

    HigherTimeFrameExitImage = "";
    LowerTimeFrameExitImage = "";

    DefaultTradeRecord::Reset();
}