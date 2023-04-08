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

#include <Wantanites\Framework\Objects\Indicators\MB\MBTracker.mqh>
#include <Wantanites\Framework\Objects\Licenses\License.mqh>

input string SmartMoneySettings = "----------------";
input int StructureBoxesToTrack = 10;
input int MinCandlesInStructure = 3;
input CandlePart StructureValidatedBy = CandlePart::Body;
input CandlePart StructureBrokenBy = CandlePart::Body;
input int MaxZonesInStructure = 5;
input CandlePart ZonesBrokenBy = CandlePart::Body;
input bool AllowMitigatedZones = false;
input ZonePart RequiredZonePartInStructure = ZonePartInMB::Whole;

// implementing
input bool AllowOverlappingZones = false;

input string Licensing = "------------";
input string LicenseKey = "";

MBTracker *MBT;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), StructureBoxesToTrack, MinCandlesInStructure, StructureValidatedBy, StructureBrokenBy, MaxZonesInStructure, ZonesBrokenBy,
                        AllowMitigatedZones, REquiredZonePartInStructure, false);

    License::CreateLicensingObjects(LicenseObjects::SmartMoney, LicenseKey);

    CreateResetButton();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(ChartID(), LicenseObjects::SmartMoney);
    delete MBT;
}

int MBsCreated = 0;
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
    MBT.DrawNMostRecentMBs(-1);
    MBT.DrawZonesForNMostRecentMBs(-1);

    return (rates_total);
}

string ButtonName = "ResetButton";
void CreateResetButton()
{
    ObjectCreate(0, buttonName, OBJ_BUTTON, 0, 100, 100);
    ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, buttonName, OBJPROP_BGCOLOR, clrGray);
    ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, 100);
    ObjectSetInteger(0, buttonName, OBJPROP_XSIZE, 200);
    ObjectSetInteger(0, buttonName, OBJPROP_YSIZE, 50);
    ObjectSetString(0, buttonName, OBJPROP_FONT, "Arial");
    ObjectSetString(0, buttonName, OBJPROP_TEXT, "Reset");
    ObjectSetInteger(0, buttonName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, buttonName, OBJPROP_SELECTABLE, 0);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == ButtonName)
        {
            MBT.Clear();
            ChartRedraw();
        }
    }
}