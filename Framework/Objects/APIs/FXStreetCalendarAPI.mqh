//+------------------------------------------------------------------+
//|                                                      TradingEconomicsAPI.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\APIs\API.mqh>
#include <Wantanites\Framework\Objects\DataObjects\AuthToken.mqh>

class FXStreetCalendarAPI : public API
{
private:
    string AuthUrl() { return "https://authorization.fxstreet.com/token"; }
    string PublicKey() { return ""; }
    string PrivateKey() { return ""; }

    AuthToken mAuthToken;

    bool RefreshAuthToken();

protected:
    virtual string BaseUrl() { return "https://calendar-api.fxstreet.com/en/api/v1/"; }

public:
    FXStreetCalendarAPI();
    ~FXStreetCalendarAPI();

    HttpResponse *GetEventsForToday();
};

FXStreetCalendarAPI::FXStreetCalendarAPI()
{
    mAuthToken = new AuthToken();
}

FXStreetCalendarAPI::~FXStreetCalendarAPI()
{
}

bool FXStreetCalendarAPI::RefreshAuthToken()
{
    JSON authData = new JSON();
    authData["grant_type"] = "client_credentials";
    authData["client_id"] = PublicKey();
    authData["client_secret"] = PrivateKey();

    string header = "Content-Type=application/x-www-form-urlencoded";

    HttpResponse *resposne = Post(AuthUrl(), header, authData);
    if (response.DidSucceed())
    {
        mAuthToken.SetNewToken(
            response.Data()["access_token"],
            response.Data()["token_type"],
            reponse.Data()["expires_in"]);

        return true;
    }

    return false;
}

HttpResponse *FXStreetCalendarAPI::GetEventsForToday()
{
    if (mAuthToken.HasExpired())
    {
        if (!RefreshAuthToken())
        {
            return;
        }
    }

    string url = BaseUrl();
}