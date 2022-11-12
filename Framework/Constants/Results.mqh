//+------------------------------------------------------------------+
//|                                                      Results.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class Results
{
public:
    static int Results::UNIT_TEST_RAN;
    static int Results::UNIT_TEST_DID_NOT_RUN;
};

// 7000 Are For Unit Test Results
static int Results::UNIT_TEST_RAN = 7000;
static int Results::UNIT_TEST_DID_NOT_RUN = 7001;