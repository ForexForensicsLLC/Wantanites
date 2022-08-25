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

class SingleTimeFrameTradeRecord : public DefaultTradeRecord
{
public:
    string EntryImage;
    string ExitImage;

    SingleTimeFrameTradeRecord();
    ~SingleTimeFrameTradeRecord();

    virtual void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
    virtual void Reset();
};

SingleTimeFrameTradeRecord::SingleTimeFrameTradeRecord()
{
    Reset();
}

SingleTimeFrameTradeRecord::~SingleTimeFrameTradeRecord() {}

void SingleTimeFrameTradeRecord::WriteHeaders(int fileHandle)
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
              "Entry Image",
              "Exit Time",
              "Exit Price",
              "Exit Stop Loss",
              "Exit Image",
              "Total Move Pips",
              "Potential RR",
              "Last State",
              "Error",
              "Error Image",
              "Notes");
}

void SingleTimeFrameTradeRecord::WriteRecord(int fileHandle)
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
              EntryImage,
              ExitTime,
              ExitPrice,
              ExitStopLoss,
              ExitImage,
              TotalMovePips(),
              PotentialRR(),
              LastState,
              Error,
              ErrorImage,
              Notes);
}

void SingleTimeFrameTradeRecord::Reset()
{
    EntryImage = "";
    ExitImage = "";

    DefaultTradeRecord::Reset();
}