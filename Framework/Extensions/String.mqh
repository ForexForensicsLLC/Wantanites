//+------------------------------------------------------------------+
//|                                                   HashUtility.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class String
{
public:
    static string Random(int length);
};

string String::Random(int length)
{
    MathSRand(GetTickCount());

    string randomString = "";
    for (int i = 0; i < length; i++)
    {
        // random character between ASCII 49 - 122
        int randomChar = MathRand() % 73 + 49;
        string s = "s";
        s = StringSetChar(s, 0, randomChar);

        randomString += s;
    }

    return randomString;
}