//+------------------------------------------------------------------+
//|                                                   ForexForensicsLicense.mqh.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\License.mqh>

class ForexForensicsLicense : public License
{
public:
    ForexForensicsLicense();
    ~ForexForensicsLicense();
};

ForexForensicsLicense::ForexForensicsLicense()
{
    mLicenseObjectNamePrefix = LicenseObjects::ForexForensics;
    mLicenseKey = String::Random(20);

    iCustom(Symbol(), Period(), "ForexForensicsLicense", licenseKey, 0, 0);
}

ForexForensicsLicense::~ForexForensicsLicense()
{
}
