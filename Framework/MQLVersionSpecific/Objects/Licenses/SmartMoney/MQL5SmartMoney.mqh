//+------------------------------------------------------------------+
//|                                                   SmartMoneyLicense.mqh.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\License.mqh>

class SmartMoneyLicense : public License
{
public:
    SmartMoneyLicense();
    ~SmartMoneyLicense();

    string Name() { return "SmartMoney"; }
};

SmartMoneyLicense::SmartMoneyLicense()
{
    mLicenseObjectNamePrefix = LicenseObjects::SmartMoney;
    mLicenseKey = String::Random(20);

    iCustom(Symbol(), Period(), "SmartMoney",
            // == Init --
            1,
            // -- Structure --
            "",
            1,
            1,
            1,
            1,
            false,
            // -- Zones --
            "",
            1,
            false,
            1,
            1,
            false,
            false,
            false,
            1,
            false,
            false,
            // -- Colors --
            "",
            clrBlack,
            clrBlack,
            clrBlack,
            clrBlack,
            clrBlack,
            clrBlack,
            // -- Licensing --
            "",
            mLicenseKey,
            false);
}

SmartMoneyLicense::~SmartMoneyLicense()
{
}
