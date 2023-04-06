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
};

SmartMoneyLicense::SmartMoneyLicense()
{
    mLicenseObjectNamePrefix = LicenseObjects::SmartMoney;
    mLicenseKey = String::Random(20);

    iCustom(Symbol(), Period(), "SmartMoney", "", 1, 1, false, false, false, false, "", -1, -1, "", mLicenseKey, 0, 0);
}

SmartMoneyLicense::~SmartMoneyLicense()
{
}
