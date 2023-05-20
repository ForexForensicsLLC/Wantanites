//+------------------------------------------------------------------+
//|                                                 ConstantValues.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class ConstantValues
{
public:
    static const int EmptyInt;
    static const double EmptyDouble;

    static const string UnsetString;
    static const string CSVDelimiter;
};

static const int ConstantValues::EmptyInt = -1;
static const double ConstantValues::EmptyDouble = -1.0;

static const string ConstantValues::UnsetString = "EMPTY";
static const string ConstantValues::CSVDelimiter = ",";