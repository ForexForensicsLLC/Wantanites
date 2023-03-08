//+------------------------------------------------------------------+
//|                                                      HttpResponse.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\JSON.mqh>

class HttpResponse
{
private:
    int mCode;
    JSON mData;
    string mHeaders;

public:
    HttpResponse(int code, string headers, char data[]);
    ~HttpResponse();

    int ResponseCode() { return mCode; }
    bool DidSucceed() { return mCode == 200; }

    JSON *Data() { return mData; }
};

HttpResponse::HttpResponse(int code, string headers, char data[])
{
    mCode = code;
    mHeaders = headers;

    string dataString = CharArrayToString(data);

    mData = new JSON();
    mData.Deseralize(dataString);
}

HttpResponse::~HttpResponse()
{
}