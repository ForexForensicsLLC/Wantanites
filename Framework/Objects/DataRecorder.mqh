//+------------------------------------------------------------------+
//|                                                DataRecorder.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\OBjects\CSVWriter.mqh>

template <typename TRecord>
class DataRecorder : public CSVWriter<TRecord>
{
private:
    CSVWriter<TRecord> *mCSVWriter;

    int mImageWidth;
    int mImageHeight;

    TRecord mPendingRecords[];

public:
    DataRecorder(string directory, string csvFileName);
    ~DataRecorder();
};

template <typename TRecord>
DataRecorder::DataRecorder(string directory, string csvFileName)
{
}

template <typename TRecord>
DataRecorder::~DataRecorder() {}
