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

#include <Wantanites\Framework\MQLVersionSpecific\Defines\MQL4Constants.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\MBTracker.mqh>
#include <Wantanites\Framework\Objects\Licenses\License.mqh>

string ButtonName = "ClearButton";

input string StructureSettings = "------- Structure ---------"; // -
input int StructureBoxesToTrack = 10;
input int MinCandlesInStructure = 3;
input CandlePart StructureValidatedBy = CandlePart::Body;
input CandlePart StructureBrokenBy = CandlePart::Body;
input bool ShowPendingStructure = true;

input string ZoneSettings = "------ Zones --------"; // -
input int MaxZonesInStructure = 5;
input bool AllowZonesAfterStructureValidation = false;
input CandlePart ZonesBrokenBy = CandlePart::Body;
input ZonePartInMB RequiredZonePartInStructure = ZonePartInMB::Whole;
input bool AllowMitigatedZones = false;
input bool AllowOverlappingZones = false; // AllowOverlappingZones (Requires AllowMitigatedZones=true)
input bool ShowPendingZones = true;
input CandlePart PendingZonesBrokenBy = CandlePart::Wick;
input bool AllowPendingMitigatedZones = true;
input bool AllowPendingOverlappingZones = false;

input string colors = "----- Colors -------"; // -
input color BullishStructure = clrLimeGreen;
input color BearishStructure = clrRed;
input color DemandZone = clrGold;
input color SupplyZone = clrMediumVioletRed;
input color PendingDemandZone = clrYellow;
input color PendingSupplyZone = clrAqua;

input string Licensing = "------ Licensing -------"; // -
input string LicenseKey = "";

MBTracker *MBT;

int OnInit()
{
    MBT = new MBTracker(false, Symbol(), Period(), StructureBoxesToTrack, MinCandlesInStructure, StructureValidatedBy, StructureBrokenBy, ShowPendingStructure,
                        MaxZonesInStructure, AllowZonesAfterStructureValidation, ZonesBrokenBy, RequiredZonePartInStructure, AllowMitigatedZones, AllowOverlappingZones,
                        ShowPendingZones, PendingZonesBrokenBy, AllowPendingMitigatedZones, AllowPendingOverlappingZones, BullishStructure, BearishStructure, DemandZone,
                        SupplyZone, PendingDemandZone, PendingSupplyZone);

    License::CreateLicensingObjects(LicenseObjects::SmartMoney, LicenseKey);

    CreateResetButton();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(ChartID(), LicenseObjects::SmartMoney);
    ObjectsDeleteAll(ChartID(), ButtonName);
    delete MBT;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])

{
    MBT.Draw();
    return (rates_total);
}

void CreateResetButton()
{
    ObjectCreate(0, ButtonName, OBJ_BUTTON, 0, 100, 100);
    ObjectSetInteger(0, ButtonName, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrGray);
    ObjectSetInteger(0, ButtonName, OBJPROP_XDISTANCE, 25);
    ObjectSetInteger(0, ButtonName, OBJPROP_YDISTANCE, 25);
    ObjectSetInteger(0, ButtonName, OBJPROP_XSIZE, 100);
    ObjectSetInteger(0, ButtonName, OBJPROP_YSIZE, 50);
    ObjectSetString(0, ButtonName, OBJPROP_FONT, "Arial");
    ObjectSetString(0, ButtonName, OBJPROP_TEXT, "Clear");
    ObjectSetInteger(0, ButtonName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, ButtonName, OBJPROP_SELECTABLE, 1);
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