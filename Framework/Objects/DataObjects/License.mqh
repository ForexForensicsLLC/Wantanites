//+------------------------------------------------------------------+
//|                                                   License.mqh.mqh |
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

enum LicenseStatus
{
    Validated,
    Pending,
    Failed
};

class License
{
private:
    int MaxFailedAttempts() { return 5; }

    bool mWasValidated;
    string mLicenseObjectNamePrefix;
    string mLicenseKey;

    int mFailedLicenseAttempts;

    string mLastError;

protected:
    bool HasLicensingObjects();

public:
    License();
    ~License();

    bool WasValidated() { return mWasValidated; }

    static void CreateLicensingObjects(string objectNamePrefix, string valueToEncode);
    bool CheckLicense(bool &reachedMaxFailedAttempts, string &error);
};

License::License()
{
    mHasLicense = false;
    mFailedLicenseAttempts = 0;
    mLastError = "";
}

License::~License()
{
}

void License::CreateLicensingObjects(string objectNamePrefix, string valueToEncode)
{
    uchar hashResult[];
    bool succeeded = Crypter::Encrypt(valueToEncode, hashResult);
    if (succeeded)
    {
        string resultAsString = String::FromCharArray(hashResult);
        int maxObjectNameLength = 20;
        int objectsToCreate = ArraySize(hashResult) / maxObjectNameLength + 1;

        for (int i = 0; i < objectsToCreate; i++)
        {
            int start = i * maxObjectNameLength;
            int count = MathMin(ArraySize(hashResult) - (i * maxObjectNameLength), maxObjectNameLength);

            string partOfEncodedValue = String::FromCharArray(hashResult, start, count);
            string objName = objectNamePrefix + IntegerToString(i) + partOfEncodedValue;

            if (!ObjectCreate(ChartID(), objName, OBJ_VLINE, 0, TimeCurrent(), 0))
            {
                mLastError = "Failed to create Licensing Object. Error: " + IntegerToString(GetLastError());
            }

            ObjectSetInteger(ChartID(), objName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
    }
    else
    {
        mLastError = "Unable to create Licensing Key. Error: " + IntegerToString(GetLastError());
    }
}

bool License::HasLicensingObjects()
{
    SortedDictionary<int, string> *encodedParts = new SortedDictionary<int, string>();

    for (int i = 0; i < ObjectsTotal(); i++)
    {
        string objName = ObjectName(i);
        if (StringFind(objName, mLicenseObjectNamePrefix) != -1)
        {
            int partNumber = IntegerToString(StringSubstr(objName, 3, 1));
            string encodedValue = StringSubstr(objName, 4, StringLen(objName));

            encodedParts.Add(partNumber, encodedValue);
        }
    }

    string encodedString = "";
    for (int i = 0; i < encodedParts.Size(); i++)
    {
        encodedString += encodedParts.GetValue(i);
    }

    delete encodedParts;
    if (encodedString == "")
    {
        mLastError = "Unable to locate License Objects.";
        mFailedLicenseAttempts += 1;

        return false;
    }

    uchar encodedValue[];
    String::ToCharArray(encodedString, encodedValue);

    string decodedValue = "";
    if (Crypter::Decrypt(encodedValue, decodedValue))
    {
        if (decodedValue == mLicenseKey)
        {
            mWasValidated = true;
            return true;
        }
        else
        {
            mLastError = "Incorrect License Key";
            mFailedLicenseAttempts += 1;

            return false;
        }
    }

    mLastError = "Unable to check License Key";
    mFailedLicenseAttempts += 1;

    return false;
}

bool License::CheckLicense(bool &reachedMaxFailedAttempts, string &error)
{
    bool hasLicensing = HasLicensingObjects();
    if (!hasLicensing && mFailedLicenseAttempts >= MaxFailedAttempts())
    {
        reachedMaxFailedAttempts = true;
        error = mLastError;
    }

    return hasLicensing;
}