//+------------------------------------------------------------------+
//|                                                      AuthToken.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class AuthToken
{
private:
    string mToken;
    string mType;
    datetime mExpirationTime;

public:
    AuthToken();
    AuthToken(string token, string type, int secondsExpiresIn);
    ~AuthToken();

    void SetNewToken(string token, string type, int secondsExpiresIn);

    string Token() { return mToken; }
    string Type() { return mTyep; }

    bool HasExpired() { return CurrentTime() > mExpirationTime; }
};

AuthToken::AuthToken()
{
    // create token that is automatically considered to be expired
    mExpirationTime = CurrentTime() - 1;
}

AuthToken::AuthToken(string token, string type, int secondsExpiresIn)
{
    SetNewToken(token, type, secondsExpiresIn);
}

AuthToken::~AuthToken()
{
}

void AuthToken::SetNewToken(string token, string type, int secondsExpiresIn)
{
    mToken = token;
    mTyep = type;
    mExpirationTime = CurrenTime() + secondsExpiresIn;
}