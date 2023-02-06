#include <WantaCapital/EAs/PrimeMemberships/PrimeMembership.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US500";
int ForcedTimeFrame = 15;

double StopLossPaddingPips = 0;
double RiskPercent = .01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 25;

int BuysSetupType = OP_BUY;
int BuysMagicNumber = MagicNumbers::NasPrimeBuys;

int SellsSetupType = OP_SELL;
int SellsMagicNumber = MagicNumbers::NasPrimeSells;

string StrategyName = "PrimeMemberships/";
string EAName = "S&P/";
string SetupTypeName = "BothAtOnce/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PrimeMembership *SPPrimeBuys;
PrimeMembership *SPPrimeSells;

// 1h
//  double AdditionalEntryPips = 20;
//  double FixedStopLossPips = 50;
//  double PipsToWaitBeforeBE = 25;
//  double BEAdditionalPips = 10;

// double AdditionalEntryPips = 15;
double AdditionalEntryPips = 60;
double FixedStopLossPips = 60;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = 5;

int OnInit()
{
    // Should only be running on the S&P on the Hourly
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    // ------------ Buys------------------
    SPPrimeBuys = new PrimeMembership(BuysMagicNumber, BuysSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                      EntryWriter, ExitWriter, ErrorWriter);
    SPPrimeBuys.SetPartialCSVRecordWriter(PartialWriter);
    SPPrimeBuys.AddPartial(10000, 100); // add .1 to account for spread

    SPPrimeBuys.mAdditionalEntryPips = AdditionalEntryPips;
    SPPrimeBuys.mFixedStopLossPips = FixedStopLossPips;
    SPPrimeBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SPPrimeBuys.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: GMT+3 1:05 - 23:50
    // SPPrimeBuys.AddTradingSession(1, 5, 23, 49);
    SPPrimeBuys.AddTradingSession(16, 30, 23, 0);

    // -----------------------------------

    // ----------- Sells -----------------
    SPPrimeSells = new PrimeMembership(SellsMagicNumber, SellsSetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                       EntryWriter, ExitWriter, ErrorWriter);
    SPPrimeSells.SetPartialCSVRecordWriter(PartialWriter);
    SPPrimeSells.AddPartial(10000, 100); // add .1 to account for spread

    SPPrimeSells.mAdditionalEntryPips = AdditionalEntryPips;
    SPPrimeSells.mFixedStopLossPips = FixedStopLossPips;
    SPPrimeSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SPPrimeSells.mBEAdditionalPips = BEAdditionalPips;

    // Time Restrictions on FTMO: GMT+3 1:05 - 23:50
    // SPPrimeSells.AddTradingSession(1, 5, 23, 49);
    SPPrimeSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SPPrimeBuys;
    delete SPPrimeSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SPPrimeBuys.Run();
    SPPrimeSells.Run();
}
