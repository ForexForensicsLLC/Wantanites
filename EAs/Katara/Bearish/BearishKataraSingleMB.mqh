//+------------------------------------------------------------------+
//|                                        BearishKataraSingleMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>
#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Objects\Ticket.mqh>

class BearishKataraSingleMB : public EA<DefaultTradeRecord>
{
public:
    Ticket *mTicket;
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;

    int mSetupType;

public:
    BearishKataraSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MBTracker *&setupMBT, MBTracker *&confirmationMBT);
    ~BearishKataraSingleMB();

    virtual int MagicNumber() { return MagicNumbers::BearishKataraSingleMB; }

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckStopTrading();
    virtual void StopTrading(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManagePendingTicket();
    virtual void ManageActiveTicket();
    virtual void CheckTicket();
    virtual void RecordOrderOpenData();
    virtual void RecordOrderCloseData();
    virtual void Reset();
};

BearishKataraSingleMB::BearishKataraSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                             MBTracker *&setupMBT, MBTracker *&confirmationMBT) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/Katara/Bearish/BearishKataraSingleMB/";
    mCSVFileName = "BearishKataraSingleMB.csv";

    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mTicket = new Ticket();

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;
    mSecondMBInConfirmationNumber = EMPTY;

    // only looking for sells
    mSetupType = OP_SELL;

    EAHelper::FillBearishKataraMagicNumbers<BearishKataraSingleMB>(this);
    EAHelper::SetSingleActiveTicket<BearishKataraSingleMB>(this);
}

BearishKataraSingleMB::~BearishKataraSingleMB()
{
    delete mMBT;
    delete mTicket;
}

void TheSunriseShatterSingleMBC::CheckSetSetup()
{
    if (EAHelper::CheckLiquidationMBSetup<TheSunriseShatterSingleMBC>(this, mSetupMBT))
    {
        mHasSetup = true;
    }
}

void TheSunriseShatterSingleMBC::Confirmation()
{
    if (EAHelper::BreakOfMB<TheSunriseShatterSingleMBC>(this, mConfirmationMBT, mSetupType))
    {
        return true;
    }
}