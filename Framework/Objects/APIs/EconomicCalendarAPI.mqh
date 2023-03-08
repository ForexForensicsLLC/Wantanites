//+------------------------------------------------------------------+
//|                                                      TradingEconomicsEconomicCalendarAPI.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\APIs\API.mqh>

class EconomicCalendarAPI : public API
{
private:
protected:
    EconomicCalendarAPI();
    ~EconomicCalendarAPI();

    virtual string BaseURL() { return "https://localhost:port/EconomicCalendar/"; }

    JSON *GetFrom(datetime utcFrom);
    JSON *GetBetween(datetime utcFrom, datetime utcTo);
};

EconomicCalendarAPI::EconomicCalendarAPI() : API()
{
}

EconomicCalendarAPI::~EconomicCalendarAPI() : API()
{
}

JSON *EconomicCalendarAPI::GetFrom(datetime utcFrom, string symbol, int impact)
{
    string url = BaseURL = "/from/" + TimeToString(utcFrom) + "?symbol=" + symbol + "&impact=" = IntergerToString(impact);
    HttpResonse response = Get(url);

    // should covnert these to an objectlist of economicevents
    return response.Data();
}

JSON *EconomicCalendarAPI::GetBetween(datetime utcFrom, datetime utcTo, string symbol, int impact)
{
    string url = BaseUrl + "/between/" + TimeToString(utcFrom) + "/" + TimeToString(utcTo) + "?symbol=" + symbol + "&impact=" = IntergerToString(impact);
    HttpResonse response = Get(url);

    // should covnert these to an objectlist of economicevents
    return response.Data();
}
