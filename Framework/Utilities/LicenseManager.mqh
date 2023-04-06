//+------------------------------------------------------------------+
//|                                                   LicenseManager.mqh.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Utilities\Crypter.mqh>
#include <Wantanites\Framework\Constants\LicenseObjects.mqh>
#include <Wantanites\Framework\Objects\DataStructures\SortedDictionary.mqh>

enum Licenses
{
    ForexForensics,
    SmartMoney
};

class LicenseManager
{
private:
    Dictionary<Licenses, LicenseStatus> mLicenses;

    ForexForensicsLicense *mForexForensicsLicense;
    SmartMoneyLicense *mSmartMoneyLicense;

public:
    LicenseManager();
    ~LicenseManager();

    void AddLicense(Licenses license);
    bool HasAllLicenses(bool &allFailed);
};

LicenseManager::LicenseManager()
{
    mLicenses = new List<License>();
    AddLicense(Licenses::ForexForensics);
}

LicenseManager::~LicenseManager()
{
}

void LicenseManager::AddLicense(Licenses license)
{
    if (!mLicenses.Add(license, LicenseStatus::Pending))
    {
        return;
    }

    switch (license)
    {
    case Licenses::ForexForensics:
        mForexForensicsLicense = new ForexForensicsLicense();
        break;
    case Licenses::SmartMoney:
        mSmartMoneyLicense = new SmartMoneyLicense();
        break;
    default:
        break;
    }
}

bool LicenseManager::HasAllLicenses(bool &allFailed)
{
    for (int i = 0; i < mLicenses.Size(); i++)
    {
        if (mLicenses[i].Status() != LicenseStatus::Pending)
        {
            continue;
        }

        switch (mLicenses[i])
        {
        case Licenses::ForexForensics:
            mForexForensicsLicense.CheckLicense();
            break;
        case Licenses::SmartMoney:
            mSmartMoneyLicense.CheckLicense();
            break;
        default:
            break;
        }
    }
}