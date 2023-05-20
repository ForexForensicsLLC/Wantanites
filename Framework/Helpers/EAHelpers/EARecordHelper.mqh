//+------------------------------------------------------------------+
//|                                                     EARecordHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\Helpers\ScreenShotHelper.mqh>
#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\IndicatorHelper\IndicatorHelper.mqh>

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\Ticket.mqh>

class EARecordHelper
{
    // =============================================================================
    // Setting Data
    // =============================================================================
private:
    template <typename TEA, typename TRecord>
    static void SetDefaultEntryTradeData(TEA &ea, TRecord &record, Ticket &ticket);
    template <typename TEA, typename TRecord>
    static void SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket);
    template <typename TEA, typename TRecord>
    static void SetForexForensicsExitTradeData(TEA &ea, TRecord &record, Ticket &ticket);

    // =============================================================================
    // Recording Data
    // =============================================================================
public:
    template <typename TEA>
    static void RecordDefaultEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordSingleTimeFrameEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordMultiTimeFrameEntryTradeRecord(TEA &ea, ENUM_TIMEFRAMES higherTimeFrame);
    template <typename TEA>
    static void RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES higherTimeFrame);
    template <typename TEA>
    static void RecordEntryCandleExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordMBEntryTradeRecord(TEA &ea, int mbNumber, MBTracker *&mbt, int mbCount, int zoneNumber);

    template <typename TEA>
    static void RecordPartialTradeRecord(TEA &ea, Ticket &partialedTicket, int newTicketNumber);

    template <typename TEA, typename TRecord>
    static void SetDefaultErrorRecordData(TEA &ea, TRecord &record, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordDefaultErrorRecord(TEA &ea, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordSingleTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordMultiTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation, ENUM_TIMEFRAMES highTimeFrame);

    template <typename TEA>
    static void RecordForexForensicsEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordForexForensicsExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordFeatureEngineeringEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordFeatureEngineeringExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordProfitTrackingExitTradeRecord(TEA &ea, Ticket &ticket);
};
/*

   ____       _   _   _               ____        _
  / ___|  ___| |_| |_(_)_ __   __ _  |  _ \  __ _| |_ __ _
  \___ \ / _ \ __| __| | '_ \ / _` | | | | |/ _` | __/ _` |
   ___) |  __/ |_| |_| | | | | (_| | | |_| | (_| | || (_| |
  |____/ \___|\__|\__|_|_| |_|\__, | |____/ \__,_|\__\__,_|
                              |___/

*/

template <typename TEA, typename TRecord>
static void EARecordHelper::SetDefaultEntryTradeData(TEA &ea, TRecord &record, Ticket &ticket)
{
    ea.mLastState = EAStates::RECORDING_ORDER_OPEN_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ticket.Number();
    record.Symbol = Symbol();
    record.OrderDirection = ticket.Type() == TicketType::Buy ? "Buy" : "Sell";
    record.AccountBalanceBefore = ticket.AccountBalanceBefore();
    record.Lots = ticket.LotSize();
    record.EntryTime = ticket.OpenTime();
    record.EntryPrice = ticket.OpenPrice();
    record.EntrySlippage = MathAbs(ticket.OpenPrice() - ticket.ExpectedOpenPrice());
    record.OriginalStopLoss = ticket.OriginalStopLoss();
}

template <typename TEA, typename TRecord>
static void EARecordHelper::SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket)
{
    ea.mLastState = EAStates::RECORDING_ORDER_CLOSE_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ticket.Number();

    // needed for computed properties
    record.Symbol = Symbol();
    record.EntryTimeFrame = ea.EntryTimeFrame();
    record.OrderDirection = ticket.Type() == TicketType::Buy ? "Buy" : "Sell";
    record.EntryPrice = ticket.OpenPrice();
    record.EntryTime = ticket.OpenTime();
    record.OriginalStopLoss = ticket.OriginalStopLoss();

    record.AccountBalanceAfter = AccountInfoDouble(ACCOUNT_BALANCE);
    record.ExitTime = ticket.CloseTime();
    record.ExitPrice = ticket.ClosePrice();

    if (!ticket.WasManuallyClosed() && ticket.CurrentStopLoss() > 0.0)
    {
        bool closedBySL = true;
        if (ticket.TakeProfit() > 0.0)
        {
            // we either closed from the TP or SL. We'll decide which one by seeing which one we are closer to
            closedBySL = MathAbs(ticket.ClosePrice() - ticket.CurrentStopLoss()) < MathAbs(ticket.ClosePrice() - ticket.TakeProfit());
        }

        if (closedBySL)
        {
            record.StopLossExitSlippage = ticket.CurrentStopLoss() - ticket.ClosePrice();
        }
        else
        {
            record.StopLossExitSlippage = 0.0;
        }
    }
    else
    {
        record.StopLossExitSlippage = 0.0;
    }

    if (ticket.DistanceRanFromOpen() > -1.0)
    {
        record.mTotalMovePips = PipConverter::PointsToPips(ticket.DistanceRanFromOpen());
    }
}

template <typename TEA, typename TRecord>
static void EARecordHelper::SetForexForensicsExitTradeData(TEA &ea, TRecord &record, Ticket &ticket)
{
    SetDefaultCloseTradeData<TEA, TRecord>(ea, record, ticket);
    record.FurthestEquityDrawdownPercent = ea.mFurthestEquityDrawdownPercent;
}

/*

   ____                        _ _               ____        _
  |  _ \ ___  ___ ___  _ __ __| (_)_ __   __ _  |  _ \  __ _| |_ __ _
  | |_) / _ \/ __/ _ \| '__/ _` | | '_ \ / _` | | | | |/ _` | __/ _` |
  |  _ <  __/ (_| (_) | | | (_| | | | | | (_| | | |_| | (_| | || (_| |
  |_| \_\___|\___\___/|_|  \__,_|_|_| |_|\__, | |____/ \__,_|\__\__,_|
                                         |___/

*/
template <typename TEA>
static void EARecordHelper::RecordDefaultEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    DefaultEntryTradeRecord *record = new DefaultEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, DefaultEntryTradeRecord>(ea, record, ticket);

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket)
{
    DefaultExitTradeRecord *record = new DefaultExitTradeRecord();
    SetDefaultCloseTradeData<TEA, DefaultExitTradeRecord>(ea, record, ticket);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordSingleTimeFrameEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    SingleTimeFrameEntryTradeRecord *record = new SingleTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, SingleTimeFrameEntryTradeRecord>(ea, record, ticket);

    record.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.mEntryCSVRecordWriter.Directory());
    ea.mEntryCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket)
{
    SingleTimeFrameExitTradeRecord *record = new SingleTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, SingleTimeFrameExitTradeRecord>(ea, record, ticket);

    record.ExitImage = ScreenShotHelper::TryTakeScreenShot(ea.mExitCSVRecordWriter.Directory());
    ea.mExitCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordMultiTimeFrameEntryTradeRecord(TEA &ea, ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameEntryTradeRecord *record = new MultiTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, MultiTimeFrameEntryTradeRecord>(ea, record);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mEntryCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != Errors::NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the entry data
        ea.RecordError(__FUNCTION__, error);
    }

    record.LowerTimeFrameEntryImage = lowerTimeFrameImage;
    record.HigherTimeFrameEntryImage = higherTimeFrameImage;

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameExitTradeRecord *record = new MultiTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, MultiTimeFrameExitTradeRecord>(ea, record, ticket);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != Errors::NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the exit data
        ea.RecordError(__FUNCTION__, error);
    }

    record.LowerTimeFrameExitImage = lowerTimeFrameImage;
    record.HigherTimeFrameExitImage = higherTimeFrameImage;

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordEntryCandleExitTradeRecord(TEA &ea, Ticket &ticket)
{
    EntryCandleExitTradeRecord *record = new EntryCandleExitTradeRecord();
    SetDefaultCloseTradeData<TEA, EntryCandleExitTradeRecord>(ea, record, ticket, ea.mEntryTimeFrame);

    int entryCandle = iBarShift(ea.mEntrySymbol, ea.mEntryTimeFrame, ticket.OpenTime());
    record.CandleOpen = iOpen(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleClose = iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleHigh = iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleLow = iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordMBEntryTradeRecord(TEA &ea, int mbNumber, MBTracker *&mbt, int mbCount, int zoneNumber)
{
    MBEntryTradeRecord *record = new MBEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, MBEntryTradeRecord>(ea, record);

    MBState *tempMBState;
    mbt.GetMB(mbNumber, tempMBState);

    ea.mCurrentSetupTicket.SelectIfOpen("Recording Open");

    int pendingMBStart = ConstantValues::EmptyInt;
    double furthestPoint = ConstantValues::EmptyInt;
    double pendingHeight = -1.0;
    double percentOfPendingMBInPrevious = -1.0;
    double rrToPendingMBVal = 0.0;

    if (ea.SetupType() == OP_BUY)
    {
        mbt.CurrentBullishRetracementIndexIsValid(pendingMBStart);
        MQLHelper::GetLowestLowBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint);

        pendingHeight = iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - furthestPoint;
        percentOfPendingMBInPrevious = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, tempMBState.HighIndex()) - furthestPoint) / pendingHeight;
        rrToPendingMBVal = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - OrderOpenPrice()) / (OrderOpenPrice() - OrderStopLoss());
    }
    else if (ea.SetupType() == OP_SELL)
    {
        mbt.CurrentBearishRetracementIndexIsValid(pendingMBStart);
        MQLHelper::GetHighestHighBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint);

        pendingHeight = furthestPoint - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart);
        percentOfPendingMBInPrevious = (furthestPoint - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, tempMBState.LowIndex())) / pendingHeight;
        rrToPendingMBVal = (OrderOpenPrice() - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart)) / (OrderStopLoss() - OrderOpenPrice());
    }

    record.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.mEntryCSVRecordWriter.Directory());
    record.RRToMBValidation = rrToPendingMBVal;
    record.MBHeight = tempMBState.Height();
    record.MBWidth = tempMBState.Width();
    record.PendingMBHeight = pendingHeight;
    record.PendingMBWidth = pendingMBStart;
    record.PercentOfPendingMBInPrevious = percentOfPendingMBInPrevious;
    record.MBCount = mbCount;
    record.ZoneNumber = zoneNumber;

    ea.mEntryCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordPartialTradeRecord(TEA &ea, Ticket &partialedTicket, int newTicketNumber)
{
    ea.mLastState = EAStates::RECORDING_PARTIAL_DATA;

    PartialTradeRecord *record = new PartialTradeRecord();

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = partialedTicket.Number();
    record.NewTicketNumber = newTicketNumber;
    record.ExpectedPartialRR = partialedTicket.mPartials[0].mRR;
    record.ActualPartialRR = partialedTicket.RRAcquired();

    ea.mPartialCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA, typename TRecord>
static void EARecordHelper::SetDefaultErrorRecordData(TEA &ea, TRecord &record, string methodName, int error, string additionalInformation)
{
    record.ErrorTime = TimeCurrent();
    record.MagicNumber = ea.MagicNumber();
    record.Symbol = Symbol();
    record.MethodName = methodName;
    record.Error = error;
    record.LastState = ea.mLastState;

    // set to unset string so when writing the value the framework doesn't think it failed because it didn't write anything
    if (additionalInformation == "")
    {
        additionalInformation = ConstantValues::UnsetString;
    }

    record.AdditionalInformation = additionalInformation;
}

template <typename TEA>
static void EARecordHelper::RecordDefaultErrorRecord(TEA &ea, string methodName, int error, string additionalInformation)
{
    DefaultErrorRecord *record = new DefaultErrorRecord();
    SetDefaultErrorRecordData<TEA, DefaultErrorRecord>(ea, record, methodName, error, additionalInformation);

    ea.mErrorCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordSingleTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation)
{
    SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, SingleTimeFrameErrorRecord>(ea, record, methodName, error, additionalInformation);

    record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(ea.mErrorCSVRecordWriter.Directory(), "", 8000, 4400);
    ea.mErrorCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordMultiTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation, ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameErrorRecord *record = new MultiTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, MultiTimeFrameErrorRecord>(ea, record, methodName, error, additionalInformation);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int screenShotError = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (screenShotError != Errors::NO_ERROR)
    {
        // don't record the error or else we could get stuck in an infinte loop
        lowerTimeFrameImage = "Error: " + IntegerToString(screenShotError);
        higherTimeFrameImage = "Error: " + IntegerToString(screenShotError);
    }

    record.LowerTimeFrameErrorImage = lowerTimeFrameImage;
    record.HigherTimeFrameErrorImage = higherTimeFrameImage;

    ea.mErrorCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordForexForensicsEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    ForexForensicsEntryTradeRecord *record = new ForexForensicsEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, ForexForensicsEntryTradeRecord>(ea, record, ticket);

    // override the magic number so that it matches the ticket that we copied the trade from
    record.MagicNumber = ticket.MagicNumber();
    record.ExpectedEntryPrice = ticket.ExpectedOpenPrice();
    record.DuringNews = EASetupHelper::CandleIsDuringEconomicEvent<TEA>(ea, iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime()));

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordForexForensicsExitTradeRecord(TEA &ea, Ticket &ticket)
{
    ForexForensicsExitTradeRecord *record = new ForexForensicsExitTradeRecord();
    SetForexForensicsExitTradeData<TEA, ForexForensicsExitTradeRecord>(ea, record, ticket);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordFeatureEngineeringEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    FeatureEngineeringEntryTradeRecord *record = new FeatureEngineeringEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, FeatureEngineeringEntryTradeRecord>(ea, record, ticket);

    int entryCandle = iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime());
    if (EASetupHelper::CandleIsDuringEconomicEvent<TEA>(ea, entryCandle))
    {
        record.DuringNews = true;

        for (int i = 0; i < ea.mEconomicEvents.Size(); i++)
        {
            if (ea.mEconomicEvents[i].Impact() > record.NewsImpact)
            {
                record.NewsImpact = ea.mEconomicEvents[i].Impact();
            }
        }
    }
    else
    {
        record.DuringNews = false;
        record.NewsImpact = -1;
    }

    record.DayOfWeek = DateTimeHelper::CurrentDayOfWeek();

    record.PreviousCandleWasBullish = CandleStickHelper::IsBullish(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasBullishEngulfing = SetupHelper::BullishEngulfing(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasBearishEngulfing = SetupHelper::BearishEngulfing(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasHammerPattern = SetupHelper::HammerCandleStickPattern(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreivousCandleWasShootingStarPattern = SetupHelper::ShootingStarCandleStickPattern(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);

    record.EntryAboveFiveEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 5, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();
    record.EntryAboveFiftyEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 50, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();
    record.EntryAboveTwoHundreadEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 200, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();

    record.FivePeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 5);
    record.TenPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 10);
    record.TwentyPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 20);
    record.FourtyPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 40);

    double rsi = IndicatorHelper::RSI(ea.EntrySymbol(), ea.EntryTimeFrame(), 14, PRICE_CLOSE, entryCandle);
    record.EntryDuringRSIAboveThirty = rsi > 30;
    record.EntryDuringRSIAboveFifty = rsi > 50;
    record.EntryDuringRSIAboveSeventy = rsi > 70;

    record.PreviousConsecutiveBullishHeikinAshiCandles = ea.mHAT.PreviousConsecutiveBullishCandles();
    record.PreviousConsecutiveBearishHeikinAshiCandles = ea.mHAT.PreviousConsecutiveBearishCandles();

    bool mostRecentStructureIsBullish = ea.mMBT.GetNthMostRecentMBsType(0) == SignalType::Bullish;
    bool inMostRecentStructureZone = EASetupHelper::CandleIsInZone<TEA>(ea, ea.mMBT, ea.mMBT.MBsCreated() - 1, entryCandle);

    record.CurrentStructureIsBullish = mostRecentStructureIsBullish;
    record.WithinDemandZone = mostRecentStructureIsBullish && inMostRecentStructureZone;
    record.WithinSupplyZone = !mostRecentStructureIsBullish && inMostRecentStructureZone;
    record.WithinPendingDemandZone = EASetupHelper::CandleIsInPendingZone<TEA>(ea, ea.mMBT, SignalType::Bullish, entryCandle);
    record.WithinPendingSupplyZone = EASetupHelper::CandleIsInPendingZone<TEA>(ea, ea.mMBT, SignalType::Bearish, entryCandle);

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordFeatureEngineeringExitTradeRecord(TEA &ea, Ticket &ticket)
{
    FeatureEngineeringExitTradeRecord *record = new FeatureEngineeringExitTradeRecord();
    SetDefaultCloseTradeData<TEA, FeatureEngineeringExitTradeRecord>(ea, record, ticket);

    record.FurthestEquityDrawdownPercent = ea.mFurthestEquityDrawdownPercent;
    record.Outcome = ticket.Profit() > 0 ? "Win" : "Lose";

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EARecordHelper::RecordProfitTrackingExitTradeRecord(TEA &ea, Ticket &ticket)
{
    ProfitTrackingExitTradeRecord *record = new ProfitTrackingExitTradeRecord();
    SetForexForensicsExitTradeData<TEA, ProfitTrackingExitTradeRecord>(ea, record, ticket);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}