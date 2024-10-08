//+------------------------------------------------------------------+
//|                                                   String.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\List.mqh>

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Extensions\String\MQ4String.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Extensions\String\MQ5String.mqh>
#endif

class String
{
public:
    static string SetChar(string s, int position, ushort asciiValue);
    static string Random(int length);

    static void ToCharArray(string value, uchar &charArray[]);
    static string FromCharArray(uchar &charArray[], int start, int count);
};

static string String::SetChar(string s, int position, ushort asciiValue)
{
    return VersionSpecificString::SetChar(s, position, asciiValue);
}

string String::Random(int length)
{
    MathSrand(GetTickCount());

    string randomString = "";
    for (int i = 0; i < length; i++)
    {
        // random character between ASCII 49 - 122
        ushort randomChar = MathRand() % 73 + 49;
        string s = "s";
        s = SetChar(s, 0, randomChar);

        randomString += s;
    }

    return randomString;
}

void String::ToCharArray(string value, uchar &charArray[])
{
    StringToCharArray(value, charArray, 0, StringLen(value));
}
static string String::FromCharArray(uchar &charArray[], int start = 0, int count = -1)
{
    int c = count;
    if (c == -1)
    {
        c == ArraySize(charArray);
    }

    return CharArrayToString(charArray, start, c);
}