//+------------------------------------------------------------------+
//|                                                   String.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class VersionSpecificString
{
public:
    static string SetChar(string s, int position, ushort asciiValue);
};

static string VersionSpecificString::SetChar(string s, int position, ushort asciiValue)
{
    StringSetCharacter(s, position, asciiValue);
    return s;
}