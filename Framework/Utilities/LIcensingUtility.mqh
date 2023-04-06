//+------------------------------------------------------------------+
//|                                                   LIcensingUtility.mqh.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\SortedDictionary.mqh>
#include <Wantanites\Framework\Constants\LicenseObjects.mqh>
#include <Wantanites\Framework\Utilities\HashUtility.mqh>

class LicensingUtility
{
public:
    static void CreateLicensingObjects(string objectNamePrefix, string valueToEncode);
    static bool HasLicensingObjects(string objectNamePrefix, string originalValue);
};

void LicensingUtility::CreateLicensingObjects(string objectNamePrefix, string valueToEncode)
{
    uchar hashResult[];
    bool succeeded = HashUtility::Encode(valueToEncode, hashResult);
    if (succeeded)
    {
        string resultAsString = String::FromCharArray(hashResult);

        int maxObjectNameLength = 50;
        int objectsToCreate = ArraySize(hashResult) / maxObjectNameLength + 1;

        for (int i = 0; i < objectsToCreate; i++)
        {
            int start = i * maxObjectNameLength;
            int count = MathMin(ArraySize(hashResult) - (i * maxObjectNameLength), maxObjectNameLength);

            string partOfEncodedValue = String::FromCharArray(hashResult, start, count);
            string objName = objectNamePrefix + IntegerToString(i) + partOfEncodedValue;

            ObjectCreate(ChartID(), objName, OBJ_VLINE, 0, TimeCurrent(), 0);
            ObjectSetInteger(ChartID(), objName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
    }
}

bool LicensingUtility::HasLicensingObjects(string objectNamePrefix, string originalValue)
{
    SortedDictionary<int, string> *encodedParts = new SortedDictionary<int, string>();

    for (int i = 0; i < ObjectsTotal(); i++)
    {
        string objName = ObjectName(i);
        if (StringFind(objName, objectNamePrefix) != -1)
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
        Print("Unable to locate License keys");
        return false;
    }

    uchar encodedValue[];
    String::ToCharArray(encodedString, encodedValue);

    string decodedValue = "";
    if (HashUtility::Decode(encodedValue, decodedValue))
    {
        if (decodedValue == originalValue)
        {
            return true;
        }
    }

    Print("Not Licensed Version.");
    return false;
}