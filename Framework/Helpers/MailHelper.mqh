//+------------------------------------------------------------------+
//|                                                   MailHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class MailHelper
{
public:
    static void SendEADeinitEmail(string ea, int reason);
};

static void MailHelper::SendEADeinitEmail(string ea, int reason)
{
    SendMail("EA Has Been Deinitalized",
             "EA: " + ea + "\n" + "Reason: " + IntegerToString(reason));
}
