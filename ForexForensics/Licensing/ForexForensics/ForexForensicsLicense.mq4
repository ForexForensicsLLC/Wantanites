//+------------------------------------------------------------------+
//|                                           ForexForensics.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 0

#include <Wantanites\Framework\Objects\Licenses\License.mqh>

input string LicenseKey = "";

int OnInit()
{
    License::CreateLicensingObjects(LicenseObjects::ForexForensics, LicenseKey);
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(ChartID(), LicenseObjects::ForexForensics);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    return (rates_total);
}