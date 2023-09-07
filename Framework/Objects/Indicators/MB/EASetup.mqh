#include <Wantanites/Framework/Objects/Indicators/MB/MBTracker.mqh>

// MB Inputs
input string InitSettings = "------ Init -------"; // -
input int BarStart = 400;                          // Bars Back to Start Calculating From (-1=All Bars)

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

MBTracker *MBT = new MBTracker(false, Symbol(), (ENUM_TIMEFRAMES)Period(), BarStart, StructureBoxesToTrack, MinCandlesInStructure, StructureValidatedBy, StructureBrokenBy,
                               ShowPendingStructure, MaxZonesInStructure, AllowZonesAfterStructureValidation, ZonesBrokenBy, RequiredZonePartInStructure, AllowMitigatedZones,
                               AllowOverlappingZones, ShowPendingZones, PendingZonesBrokenBy, AllowPendingMitigatedZones, AllowPendingOverlappingZones, BullishStructure,
                               BearishStructure, DemandZone, SupplyZone, PendingDemandZone, PendingSupplyZone);