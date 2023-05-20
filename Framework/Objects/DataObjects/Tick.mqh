//+------------------------------------------------------------------+
//|                                                   Tick.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

enum TickStatus
{
    Invalid,
    Valid
};

class Tick
{
private:
    MqlTick mTick;
    TickStatus mStatus;

    bool IsValid();

public:
    Tick();
    ~Tick();

    string DisplayName() { return "Tick"; }

    void operator=(MqlTick &mqlTick) { mTick = mqlTick; }

    void SetStatus(TickStatus status) { mStatus = status; }

    double Bid();
    double Ask();
    datetime Time();
};

Tick::Tick()
{
    mStatus = TickStatus::Invalid;
}

Tick::~Tick()
{
}

bool Tick::IsValid()
{
    if (mStatus == TickStatus::Invalid)
    {
        SendMail("Invalid Tick", "Time: " + TimeToString(TimeCurrent()));
        Print("Invalid Tick at ", TimeToString(TimeCurrent()));

        return false;
    }

    return true;
}

double Tick::Bid()
{
    if (!IsValid())
    {
        return ConstantValues::EmptyDouble;
    }

    return mTick.bid;
}

double Tick::Ask()
{
    if (!IsValid())
    {
        return ConstantValues::EmptyDouble;
    }

    return mTick.ask;
}

datetime Tick::Time()
{
    if (!IsValid())
    {
        return ConstantValues::EmptyInt;
    }

    return mTick.time;
}
