//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\ForexForensicsEntryTradeRecord.mqh>

class FeatureEngineeringEntryTradeRecord : public ForexForensicsEntryTradeRecord
{
public:
    FeatureEngineeringEntryTradeRecord();
    ~FeatureEngineeringEntryTradeRecord();

    int NewsImpact;
    int DayOfWeek;
    bool PreviousCandleWasBullish;
    bool PreviousCandleWasBullishEngulfing;
    bool PreviousCandleWasBearishEngulfing;
    bool PreviousCandleWasHammerPattern;
    bool PreivousCandleWasShootingStarPattern;
    bool EntryAboveFiveEMA;
    bool EntryAboveFiftyEMA;
    bool EntryAboveTwoHundreadEMA;
    double FivePeriodOBVAverageChange;
    double TenPeriodOBVAverageChange;
    double TwentyPeriodOBVAverageChange;
    double FourtyPeriodOBVAverageChange;
    bool EntryDuringRSIAboveThirty;
    bool EntryDuringRSIAboveFifty;
    bool EntryDuringRSIAboveSeventy;
    int PreviousConsecutiveBullishHeikinAshiCandles;
    int PreviousConsecutiveBearishHeikinAshiCandles;
    bool CurrentStructureIsBullish;
    bool WithinDemandZone;
    bool WithinSupplyZone;
    bool WithinPendingDemandZone;
    bool WithinPendingSupplyZone;

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

FeatureEngineeringEntryTradeRecord::FeatureEngineeringEntryTradeRecord() : ForexForensicsEntryTradeRecord() {}
FeatureEngineeringEntryTradeRecord::~FeatureEngineeringEntryTradeRecord() {}

void FeatureEngineeringEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "News Impact");
    FileHelper::WriteString(fileHandle, "Day of Week");
    FileHelper::WriteString(fileHandle, "Previous Candle Was Bullish");
    FileHelper::WriteString(fileHandle, "Previous Candle Was Bullish Engulfing");
    FileHelper::WriteString(fileHandle, "Previous Candle Was Bearish Engulfing");
    FileHelper::WriteString(fileHandle, "Previous Candle Was Hammer Pattern");
    FileHelper::WriteString(fileHandle, "Previuos Candle Was Shooting Star Pattern");
    FileHelper::WriteString(fileHandle, "Entry Above 5 EMA");
    FileHelper::WriteString(fileHandle, "Entry Above 50 EMA");
    FileHelper::WriteString(fileHandle, "Entry Above 200 EMA");
    FileHelper::WriteString(fileHandle, "5 Period On Balance Volumn Average Change");
    FileHelper::WriteString(fileHandle, "10 Period On Balance Volumn Average Change");
    FileHelper::WriteString(fileHandle, "20 Period On Balance Volumn Average Change");
    FileHelper::WriteString(fileHandle, "40 Period On Balance Volumn Average Change");
    FileHelper::WriteString(fileHandle, "Entry During RSI Above 30");
    FileHelper::WriteString(fileHandle, "Entry During RSI Above 50");
    FileHelper::WriteString(fileHandle, "Entry During RSI Above 70");
    FileHelper::WriteString(fileHandle, "Previous Consecutive Bullish Heikin Ashi Candles");
    FileHelper::WriteString(fileHandle, "Previous Consecutive Bearish Heikin Ashi Candles");
    FileHelper::WriteString(fileHandle, "Current Structure Is Bullish");
    FileHelper::WriteString(fileHandle, "Entry Within Demand Zone");
    FileHelper::WriteString(fileHandle, "Entry Within Supply Zone");
    FileHelper::WriteString(fileHandle, "Entry Within Pending Demand Zone");
    FileHelper::WriteString(fileHandle, "Entry Within Pending Supply Zone", writeDelimiter);
}
void FeatureEngineeringEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteInteger(fileHandle, NewsImpact);
    FileHelper::WriteInteger(fileHandle, DayOfWeek);
    FileHelper::WriteInteger(fileHandle, PreviousCandleWasBullish);
    FileHelper::WriteInteger(fileHandle, PreviousCandleWasBullishEngulfing);
    FileHelper::WriteInteger(fileHandle, PreviousCandleWasBearishEngulfing);
    FileHelper::WriteInteger(fileHandle, PreviousCandleWasHammerPattern);
    FileHelper::WriteInteger(fileHandle, PreivousCandleWasShootingStarPattern);
    FileHelper::WriteInteger(fileHandle, EntryAboveFiveEMA);
    FileHelper::WriteInteger(fileHandle, EntryAboveFiftyEMA);
    FileHelper::WriteInteger(fileHandle, EntryAboveTwoHundreadEMA);
    FileHelper::WriteDouble(fileHandle, FivePeriodOBVAverageChange, Digits());
    FileHelper::WriteDouble(fileHandle, TenPeriodOBVAverageChange, Digits());
    FileHelper::WriteDouble(fileHandle, TwentyPeriodOBVAverageChange, Digits());
    FileHelper::WriteDouble(fileHandle, FourtyPeriodOBVAverageChange, Digits());
    FileHelper::WriteInteger(fileHandle, EntryDuringRSIAboveThirty);
    FileHelper::WriteInteger(fileHandle, EntryDuringRSIAboveFifty);
    FileHelper::WriteInteger(fileHandle, EntryDuringRSIAboveSeventy);
    FileHelper::WriteInteger(fileHandle, PreviousConsecutiveBullishHeikinAshiCandles);
    FileHelper::WriteInteger(fileHandle, PreviousConsecutiveBearishHeikinAshiCandles);
    FileHelper::WriteInteger(fileHandle, CurrentStructureIsBullish);
    FileHelper::WriteInteger(fileHandle, WithinDemandZone);
    FileHelper::WriteInteger(fileHandle, WithinSupplyZone);
    FileHelper::WriteInteger(fileHandle, WithinPendingDemandZone);
    FileHelper::WriteInteger(fileHandle, WithinPendingSupplyZone, writeDelimiter);
}

void FeatureEngineeringEntryTradeRecord::ReadRow(int fileHandle)
{
    ForexForensicsEntryTradeRecord::ReadRow(fileHandle);
    NewsImpact = StringToInteger(FileReadString(fileHandle));
    DayOfWeek = StringToInteger(FileReadString(fileHandle));
    PreviousCandleWasBullish = FileHelper::ReadBool(fileHandle);
    PreviousCandleWasBullishEngulfing = FileHelper::ReadBool(fileHandle);
    PreviousCandleWasBearishEngulfing = FileHelper::ReadBool(fileHandle);
    PreviousCandleWasHammerPattern = FileHelper::ReadBool(fileHandle);
    PreivousCandleWasShootingStarPattern = FileHelper::ReadBool(fileHandle);
    EntryAboveFiveEMA = FileHelper::ReadBool(fileHandle);
    EntryAboveFiftyEMA = FileHelper::ReadBool(fileHandle);
    EntryAboveTwoHundreadEMA = FileHelper::ReadBool(fileHandle);
    FivePeriodOBVAverageChange = StringToDouble(FileReadString(fileHandle));
    TenPeriodOBVAverageChange = StringToDouble(FileReadString(fileHandle));
    TwentyPeriodOBVAverageChange = StringToDouble(FileReadString(fileHandle));
    FourtyPeriodOBVAverageChange = StringToDouble(FileReadString(fileHandle));
    EntryDuringRSIAboveThirty = FileHelper::ReadBool(fileHandle);
    EntryDuringRSIAboveFifty = FileHelper::ReadBool(fileHandle);
    EntryDuringRSIAboveSeventy = FileHelper::ReadBool(fileHandle);
    PreviousConsecutiveBullishHeikinAshiCandles = StringToInteger(FileReadString(fileHandle));
    PreviousConsecutiveBearishHeikinAshiCandles = StringToInteger(FileReadString(fileHandle));
    CurrentStructureIsBullish = FileHelper::ReadBool(fileHandle);
    WithinDemandZone = FileHelper::ReadBool(fileHandle);
    WithinSupplyZone = FileHelper::ReadBool(fileHandle);
    WithinPendingDemandZone = FileHelper::ReadBool(fileHandle);
    WithinPendingSupplyZone = FileHelper::ReadBool(fileHandle);
}