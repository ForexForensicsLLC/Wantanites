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
private:
    static bool mEnabled;

public:
    static void Enable() { mEnabled = true; }
    static void Disable() { mEnabled = false; }

    static void Send(string title, string body);

    static void SendEADeinitEmail(string ea, int reason);
};

bool MailHelper::mEnabled = true;

static void MailHelper::Send(string title, string body)
{
    if (mEnabled)
    {
        SendMail(title, body);
    }
}

static void MailHelper::SendEADeinitEmail(string ea, int reason)
{
    Send("EA Has Been Deinitalized", "EA: " + ea + "\n" + "Reason: " + IntegerToString(reason));
}
