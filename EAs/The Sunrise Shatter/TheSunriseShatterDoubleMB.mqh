//+------------------------------------------------------------------+
//|                                                       Double.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

class TheSunriseShatterDoubleMB : public EA<DefaultTradeRecord>
{
private:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mMBStopOrderTicket;
    int mSetupType;
    int mSecondMBInSetupNumber;

public:
    TheSunriseShatterDoubleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterDoubleMB();

    static int MagicNumber;

    virtual void FillStrategyMagicNumbers();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void CheckRecordOrderCloseData();

    virtual void Manage();
    virtual void CheckInvalidateSetup();
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();
};

static int TheSunriseShatterDoubleMB::MagicNumber = 10004;

TheSunriseShatterDoubleMB::TheSunriseShatterDoubleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                                     MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterDoubleMB/";
    mCSVFileName = "TheSunriseShatterDoubleMB.csv";

    mMRFTS = mrfts;
    mMBT = mbt;

    FillStrategyMagicNumbers();
}

TheSunriseShatterDoubleMB::~TheSunriseShatterDoubleMB()
{
}

void TheSunriseShatterDoubleMB::FillStrategyMagicNumbers()
{
    ArrayResize(mStrategyMagicNumbers, 3);

    mStrategyMagicNumbers[0] = MagicNumber;
    mStrategyMagicNumbers[1] = TheSunriseShatterSingleMB::MagicNumber;
}
