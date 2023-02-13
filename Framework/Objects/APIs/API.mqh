//+------------------------------------------------------------------+
//|                                                      TradingEconomicsAPI.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataObjects\HttpResponse.mqh>

class API
{
private:
    datetime mLastRequestTime;

protected:
    API();
    ~API();

    virtual string BaseUrl() = NULL;
    virtual int MinRequestIntervalSeconds() { return 1; }

    static void CheckLastRequestTime();

    static HttpResposne *Get(string url, string headers, int timeout);
    static HttpResponse *Post(string url, string headers, JSON data, int timeout);
};

API::API()
{
    mLastRequestTime = 0;
}

API::~API()
{
}

static void API::CheckLastRequestTime()
{
    if (TimeCurrent() - mLastRequestTime > MinRequestIntervalSeconds())
    {
        return;
    }

    // turn seconds into milliseconds
    Sleep(MinRequestIntervalSeconds() * 1000);
}

static HttpReponse *API::Get(string url, string headers = "", int timeout = 3000)
{
    CheckLastRequestTime();

    char dataToSend[];
    char responseData[];
    string responseHeaders;

    int result = WebRequest("GET", url, headers, timeout, dataToSend, responseData, responseHeaders);
    mLastRequestTime = CurrentTime();

    return new HttpResponse(result, responseHeaders, responseData);
}

static HttpResponse *API::Post(string url, string headers, JSON data, int timeout = 3000)
{
    CheckLastRequestTime();

    char dataToSend[];
    char responseData[];
    string responseHeaders;

    StringToCharArray(data.Serialize(), dataToSend);

    int result = WebRequest("POST", url, headers, timeout, dataToSend, responseData, responseHeaders);
    mLastRequestTime = CurrentTime();

    return new HttpResponse(result, responseHeaders, responseData);
}
