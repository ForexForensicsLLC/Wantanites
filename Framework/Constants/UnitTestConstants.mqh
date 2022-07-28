//+------------------------------------------------------------------+
//|                                            UnitTestConstants.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
class UnitTestConstants
{
public:
    static int UNIT_TEST_RAN;
    static int UNIT_TEST_DID_NOT_RUN;
};

static int UnitTestConstants::UNIT_TEST_RAN = 1001;
static int UnitTestConstants::UNIT_TEST_DID_NOT_RUN = 1002;
