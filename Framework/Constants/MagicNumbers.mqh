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
    static int UJTimeRangeBreakoutBuys;
    static int UJTimeRangeBreakoutSells;

    static int NasMorningFractalBreakBuys;
    static int NasMorningFractalBreakSells;

    static int DowMorningCandleLiquidationBuys;
    static int DowMorningCandleLiquidationSells;

    static int NasMorningPriceRangeBuys;
    static int NasMorningPriceRangeSells;

    static int OilMorningPriceRangeBuys;
    static int OilMorningPriceRangeSells;
};

static int MagicNumbers::UJTimeRangeBreakoutBuys = 10067;
static int MagicNumbers::UJTimeRangeBreakoutSells = 10068;

static int MagicNumbers::NasMorningFractalBreakBuys = 10069;
static int MagicNumbers::NasMorningFractalBreakSells = 10070;

static int MagicNumbers::DowMorningCandleLiquidationBuys = 10071;
static int MagicNumbers::DowMorningCandleLiquidationSells = 10072;

static int MagicNumbers::NasMorningPriceRangeBuys = 10073;
static int MagicNumbers::NasMorningPriceRangeSells = 10074;

static int MagicNumbers::OilMorningPriceRangeBuys = 10075;
static int MagicNumbers::OilMorningPriceRangeSells = 10076;
