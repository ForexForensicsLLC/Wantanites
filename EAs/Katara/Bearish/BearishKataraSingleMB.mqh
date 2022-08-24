//+------------------------------------------------------------------+
//|                                        BearishKataraSingleMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>

class BearishKataraSingleMB : public EA<DefaultTradeRecord>
{
private:
public:
    Ticket *mTicket;
    int mFirstMBInSetupNumber;
    int mSetupType;
    MBTracker *mMBT;

    BearishKataraSingleMB();
    ~BearishKataraSingleMB();
};

BearishKataraSingleMB::BearishKataraSingleMB() : EA(1, 1, 1, 1)
{
    EAHelper<BearishKataraSingleMB>::CheckTicket(this);
}

BearishKataraSingleMB::~BearishKataraSingleMB()
{
}
