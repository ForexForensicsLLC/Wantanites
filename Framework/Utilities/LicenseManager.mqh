//+------------------------------------------------------------------+
//|                                                   LicenseManager.mqh.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Licenses\Index.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>

enum Licenses
{
    ForexForensics,
    SmartMoney
};

class LicenseManager
{
private:
    List<Licenses> *mLicenses;

    LicenseStatus mLicenseCheckStatus;

    ForexForensicsLicense *mForexForensicsLicense;
    SmartMoneyLicense *mSmartMoneyLicense;

    template <typename TLicense>
    void CheckLicenseStatus(TLicense &license, int &validatedCount, int &failedCount);

public:
    LicenseManager();
    ~LicenseManager();

    void AddLicense(Licenses license);
    bool HasAllLicenses(bool &allFailed);
};

LicenseManager::LicenseManager()
{
    mLicenseCheckStatus = LicenseStatus::Pending;

    mLicenses = new List<Licenses>();
    AddLicense(Licenses::ForexForensics);
}

LicenseManager::~LicenseManager()
{
    for (int i = 0; i < mLicenses.Size(); i++)
    {
        switch (mLicenses[i])
        {
        case Licenses::ForexForensics:
            delete mForexForensicsLicense;
            break;
        case Licenses::SmartMoney:
            delete mSmartMoneyLicense;
            break;
        default:
            break;
        }
    }

    delete mLicenses;
}

void LicenseManager::AddLicense(Licenses license)
{
    if (mLicenses.Contains(license))
    {
        return;
    }

    mLicenses.Add(license);

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

bool LicenseManager::HasAllLicenses(bool &allFinished)
{
    if (mLicenseCheckStatus == LicenseStatus::Failed)
    {
        allFinished = true;
        return false;
    }
    else if (mLicenseCheckStatus == LicenseStatus::Validated)
    {
        allFinished = true;
        return true;
    }

    int validatedCount = 0;
    int failedCount = 0;

    for (int i = 0; i < mLicenses.Size(); i++)
    {
        switch (mLicenses[i])
        {
        case Licenses::ForexForensics:
            mForexForensicsLicense.CheckLicense();
            CheckLicenseStatus<ForexForensicsLicense>(mForexForensicsLicense, validatedCount, failedCount);
            break;
        case Licenses::SmartMoney:
            mSmartMoneyLicense.CheckLicense();
            CheckLicenseStatus<SmartMoneyLicense>(mSmartMoneyLicense, validatedCount, failedCount);
            break;
        default:
            break;
        }
    }

    if (failedCount > 0)
    {
        mLicenseCheckStatus = LicenseStatus::Failed;
    }
    else if (validatedCount == mLicenses.Size())
    {
        mLicenseCheckStatus = LicenseStatus::Validated;
    }

    allFinished = mLicenseCheckStatus != LicenseStatus::Pending;
    return mLicenseCheckStatus == LicenseStatus::Validated;
}

template <typename TLicense>
void LicenseManager::CheckLicenseStatus(TLicense &license, int &validatedCount, int &failedCount)
{
    if (license.Status() == LicenseStatus::Validated)
    {
        validatedCount += 1;
    }
    else if (license.Status() == LicenseStatus::Failed)
    {
        failedCount += 1;
    }
}