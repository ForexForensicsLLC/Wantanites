//+------------------------------------------------------------------+
//|                                                 MagicNumbers.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class MagicNumbers
{
public:
    static int TheSunriseShatterSingleMB;
    static int TheSunriseShatterDoubleMB;
    static int TheSunriseShatterLiquidationMB;

    static int BearishKataraSingleMB;
    static int BearishKataraDoubleMB;
    static int BearishKataraLiquidationMB;

    static int BullishKataraSingleMB;
    static int BullishKataraDoubleMB;
    static int BullishKataraLiquidationMB;
};

static int MagicNumbers::TheSunriseShatterSingleMB = 10003;
static int MagicNumbers::TheSunriseShatterDoubleMB = 10004;
static int MagicNumbers::TheSunriseShatterLiquidationMB = 10005;

static int MagicNumbers::BearishKataraSingleMB = 10006;
static int MagicNumbers::BearishKataraDoubleMB = 10007;
static int MagicNumbers::BearishKataraLiquidationMB = 10008;

static int MagicNumbers::BullishKataraSingleMB = 10009;
static int MagicNumbers::BullishKataraDoubleMB = 10010;
static int MagicNumbers::BullishKataraLiquidationMB = 10011;
