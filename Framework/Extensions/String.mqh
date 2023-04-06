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

class String
{
public:
    static string Random(int length);
    static void SplitStringNumber(string numberString, int period, List<int> &numbers);

    static void ToCharArray(string value, uchar &charArray[]);
    static string FromCharArray(uchar &charArray[], int start, int count);
};

string String::Random(int length)
{
    MathSrand(GetTickCount());

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

void String::SplitStringNumber(string numberString, int period, List<int> &numbers)
{
    int length = StringLen(numberString);
    if (length < period)
    {
        Print("String is less than period");
        return;
    }

    string tempNumberString = numberString;
    while (tempNumberString != "")
    {
        Print("Temp Number String: ", tempNumberString);
        int number = StrToInteger(StringSubstr(tempNumberString, 0, 2));
        Print("Number: ", number);
        numbers.Add(number);

        tempNumberString = StringSubstr(tempNumberString, 2, StringLen(tempNumberString));
    }
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