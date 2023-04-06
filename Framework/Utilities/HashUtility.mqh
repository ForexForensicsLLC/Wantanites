//+------------------------------------------------------------------+
//|                                                   HashUtility.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Extensions\String.mqh>

class HashUtility
{
private:
    static string Key() { return "b6Dqhs6jFX4nZgNnJ9VPaskldjfklji2"; }
    static string Salt() { return "asashdfuiofhslfnaklhwo124wh129h1"; }

    static int HashMethod() { return CRYPT_AES256; }

public:
    static bool Encode(string value, uchar &result[]);
    static bool Decode(uchar &encodedValue[], string &result);
};

static bool HashUtility::Encode(string value, uchar &result[])
{
    value += Salt();

    uchar valueAsCharArray[];
    String::ToCharArray(value, valueAsCharArray);

    uchar keyAsCharArray[];
    String::ToCharArray(Key(), keyAsCharArray);

    return CryptEncode(HashMethod(), valueAsCharArray, keyAsCharArray, result) > 0;
}

static bool HashUtility::Decode(uchar &encodedValue[], string &result)
{
    uchar keyAsCharArray[];
    String::ToCharArray(Key(), keyAsCharArray);

    uchar resultAsCharArray[];

    GetLastError();
    int bytes = CryptDecode(HashMethod(), encodedValue, keyAsCharArray, resultAsCharArray);
    if (bytes > 0)
    {
        result = String::FromCharArray(resultAsCharArray);
        if (StringReplace(result, Salt(), "") == -1)
        {
            return false;
        }

        return true;
    }
    else
    {
        Print("Bytes: ", bytes, ", Error: ", GetLastError());
        result = "";
    }

    return false;
}