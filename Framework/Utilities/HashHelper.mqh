//+------------------------------------------------------------------+
//|                                                   HashUtility.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class HashUtility
{
private:
    static string Key() { return "b6Dqhs6jFX4nZgNnJ9VPaskldjfklji23u409asojfkasdjfio2uj20935uosjdkljf2io5u12309sjdfklj2o3ij501u50jsig23io0129yu6091sdigj2po3609126u"; }
    static string Salt() { return "asashdfuiofhslfnaklhwo124wh129h12i4n; " }

    static int HashMethod() { return CRYPT_HASH_SHA256; }

public:
    static int Encode(string value, char &result[]);
    static string Decode(char &encodedValue[], string &result);
};

static int HashUtility::Encode(string value, char &result[])
{
    value += Salt();

    char valueAsCharArray[];
    StringToCharArray(value, valueAsCharArray);

    char keyAsCharArray[];
    StringToCharArray(Key(), keyAsCharArray);

    char result[];
    return CryptEncode(HashMethod(), valueAsCharArray, keyAsCharArray, result);
}

static int HashUtility::Decode(char &encodedValue[], string &result)
{
    char keyAsCharArray[];
    StringToCharArray(Key(), keyAsCharArray);

    char resultAsCharArray[];

    int bytes = CryptDecode(HashMethod(), encodedValue, keyAsCharArray, resultAsCharArray);
    if (bytes > 0)
    {
        result = CharArrayToString(resultAsCharArray);
        if (StringReplace(result, Salt(), "") == -1)
        {
            return 0;
        }
    }
    else
    {
        result = "";
    }

    return bytes;
}