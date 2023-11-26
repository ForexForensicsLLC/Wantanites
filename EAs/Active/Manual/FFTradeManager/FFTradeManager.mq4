//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Active/Manual/FFTradeManager/FFTradeManager.mqh>

bool ButtonOn = false;
string ButtonName = "OnOffButton";

string Directory = "FFTradeManager/";

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

FFTradeManager *BuyEA;
FFTradeManager *SellEA;

FFTradeManager *BuyStopEA;
FFTradeManager *SellStopEA;

// --- EA Inputs ---
int MaxCurrentSetupTradesAtOnce = ConstantValues::EmptyInt;
int MaxTradesPerDay = ConstantValues::EmptyInt;
double StopLossPaddingPips = 0.0;
double MaxSpreadPips = ConstantValues::EmptyDouble;

input int OrderType = 1; // 1=Buy,2=Sell,3=BuyLimit,4=SellLimit,5=BuyStop,6=SellStop
input double MaxRiskPercent = 2;
input double TakeProfitRR = 3;

int OnInit()
{
    TS = new TradingSession();

    BuyEA = new FFTradeManager(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, MaxRiskPercent, EntryWriter, ExitWriter, ErrorWriter, TakeProfitRR, (TicketType)OrderType);
    BuyEA.AddTradingSession(TS);

    SellEA = new FFTradeManager(-1, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, MaxRiskPercent, EntryWriter, ExitWriter, ErrorWriter, TakeProfitRR, (TicketType)OrderType);
    SellEA.AddTradingSession(TS);

    BuyStopEA = new FFTradeManager(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, MaxRiskPercent, EntryWriter, ExitWriter, ErrorWriter, TakeProfitRR, (TicketType)OrderType);
    BuyStopEA.AddTradingSession(TS);

    SellStopEA = new FFTradeManager(-1, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, MaxRiskPercent, EntryWriter, ExitWriter, ErrorWriter, TakeProfitRR, (TicketType)OrderType);
    SellStopEA.AddTradingSession(TS);

    CreateOnOffButton();

    BuyEA.Run();
    SellEA.Run();

    BuyStopEA.Run();
    SellStopEA.Run();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete BuyEA;
    delete SellEA;

    delete BuyStopEA;
    delete SellStopEA;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;

    ObjectsDeleteAll(ChartID(), ButtonName);
}

void OnTick()
{
    BuyEA.Run();
    SellEA.Run();

    BuyStopEA.Run();
    SellStopEA.Run();
}

void CreateOnOffButton()
{
    ObjectCreate(0, ButtonName, OBJ_BUTTON, 0, 100, 100);
    ObjectSetInteger(0, ButtonName, OBJPROP_XDISTANCE, 25);
    ObjectSetInteger(0, ButtonName, OBJPROP_YDISTANCE, 25);
    ObjectSetInteger(0, ButtonName, OBJPROP_XSIZE, 100);
    ObjectSetInteger(0, ButtonName, OBJPROP_YSIZE, 50);
    ObjectSetString(0, ButtonName, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, ButtonName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, ButtonName, OBJPROP_SELECTABLE, 1);
    ObjectSetInteger(0, ButtonName, OBJPROP_COLOR, clrWhite);

    SetButtonOffStyle();
}

void SetButtonOnStyle()
{
    ObjectSetString(0, ButtonName, OBJPROP_TEXT, "Off");
    ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrRed);
}

void SetButtonOffStyle()
{
    ObjectSetString(0, ButtonName, OBJPROP_TEXT, "On");
    ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrGreen);
}

bool IgnoreChartClick = false;
bool IgnoreButtonClick = false;

double StopOrderEntry = 0.0;
double StopOrderSL = 0.0;

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_DRAG)
    {
        IgnoreButtonClick = true;
        IgnoreChartClick = true;
    }
    else if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (IgnoreButtonClick)
        {
            IgnoreButtonClick = false;
            return;
        }

        ToggleButton();
        IgnoreChartClick = true;
    }
    else if (id == CHARTEVENT_CLICK && ButtonOn)
    {
        if (IgnoreChartClick)
        {
            IgnoreChartClick = false;
            return;
        }

        if (OrderType == 0)
        {
            PlaceMarketOrder(lparam, dparam);
        }
        else if (OrderType == 5 || OrderType == 6)
        {
            TryPlaceStopOrder(lparam, dparam);
        }
    }
}

void ToggleButton()
{
    if (ButtonOn == true)
    {
        ButtonOn = false;
        SetButtonOffStyle();
    }
    else
    {
        ButtonOn = true;
        SetButtonOnStyle();
    }
}

void PlaceMarketOrder(long lparam, double dparam)
{
    int subwindow = 0;
    datetime time;
    double stopLoss;

    ChartXYToTimePrice(ChartID(), lparam, dparam, subwindow, time, stopLoss);

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        Print("Couldn't Get Tick");
        return;
    }

    if (stopLoss < currentTick.bid)
    {
        BuyEA.mStopLossPrice = stopLoss;
        BuyEA.PlaceOrders();

        if (!BuyEA.mCurrentSetupTickets.IsEmpty())
        {
            ToggleButton();
        }
    }
    else if (stopLoss > currentTick.ask)
    {
        SellEA.mStopLossPrice = stopLoss;
        SellEA.PlaceOrders();

        if (!SellEA.mCurrentSetupTickets.IsEmpty())
        {
            ToggleButton();
        }
    }
}

void TryPlaceStopOrder(long lparam, double dparam)
{
    int subwindow = 0;
    datetime time;
    double stopLoss;

    if (StopOrderEntry == 0.0)
    {
        Print("Setting Entry");
        ChartXYToTimePrice(ChartID(), lparam, dparam, subwindow, time, StopOrderEntry);
    }
    else
    {
        Print("Setting Exit");
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            Print("Couldn't Get Tick");
            return;
        }

        ChartXYToTimePrice(ChartID(), lparam, dparam, subwindow, time, StopOrderSL);
        if (StopOrderEntry > currentTick.ask)
        {
            BuyStopEA.mEntryPrice = StopOrderEntry;
            BuyStopEA.mStopLossPrice = StopOrderSL;
            BuyStopEA.PlaceOrders();

            if (!BuyStopEA.mCurrentSetupTickets.IsEmpty())
            {
                ToggleButton();
            }
        }
        else if (StopOrderEntry < currentTick.bid)
        {
            SellStopEA.mEntryPrice = StopOrderEntry;
            SellStopEA.mStopLossPrice = StopOrderSL;
            SellStopEA.PlaceOrders();

            if (!SellStopEA.mCurrentSetupTickets.IsEmpty())
            {
                ToggleButton();
            }
        }

        StopOrderEntry = 0.0;
        StopOrderSL = 0.0;
    }
}
