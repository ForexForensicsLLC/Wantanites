//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingle.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EAs\Base\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class TheSunriseShatterSingle : public EA
{
private:
	MinROCFromTimeStamp *mMRFTS;
	MBTracker *mMBT;

	int mMBStopOrderTicket;
	int mSetupType;
	int mFirstMBInSetupNumber;

public:
	TheSunriseShatterSingle(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt);
	~TheSunriseShatterSingle();

	static int MagicNumber;

	virtual void FillStrategyMagicNumbers();
	virtual void Manage();
	virtual void CheckInvalidateSetup();
	virtual bool AllowedToTrade();
	virtual bool Confirmation();
	virtual void PlaceOrders();
	virtual void CheckSetSetup();
	virtual void Reset();
	virtual void Run();
};

static int TheSunriseShatterSingle::MagicNumber = 10003;

TheSunriseShatterSingle::TheSunriseShatterSingle(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
	: EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
	mMRFTS = mrfts;
	mMBT = mbt;

	FillStrategyMagicNumbers();
}

TheSunriseShatterSingle::~TheSunriseShatterSingle()
{
}

void TheSunriseShatterSingle::FillStrategyMagicNumbers()
{
	ArrayResize(mStrategyMagicNumbers, 3);
	mStrategyMagicNumbers[0] = MagicNumber;
}

void TheSunriseShatterSingle::Manage()
{
	if (mMBStopOrderTicket == EMPTY)
	{
		return;
	}

	bool isPendingOrder = false;
	int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPendingOrder);

	if (isPendingOrder)
	{
		int editStopLossError = OrderHelper::CheckEditStopLossForMostRecentMBStopOrder(
			mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mFirstMBInSetupNumber, mMBT, mMBStopOrderTicket);
	}
	else
	{
		bool succeeeded = false;
		OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(mMBStopOrderTicket, mStopLossPaddingPips, mMaxSpreadPips, mFirstMBInSetupNumber, mSetupType, mMBT, succeeeded);
	}
}

void TheSunriseShatterSingle::CheckInvalidateSetup()
{
	if (!mHasSetup)
	{
		return;
	}

	bool brokeRangeStart = false;
	int brokeRangeError = SetupHelper::BrokeMBRangeStart(mFirstMBInSetupNumber, mMBT, brokeRangeStart);
	bool doubleMB = mMBT.MBIsMostRecent(mFirstMBInSetupNumber + 1) && mMBT.HasNMostRecentConsecutiveMBs(2);

	if (mMRFTS.CrossedOpenPriceAfterMinROC() || brokeRangeStart || doubleMB || brokeRangeError != ERR_NO_ERROR)
	{
		mHasSetup = false;
		mStopTrading = true;

		if (mMBStopOrderTicket == EMPTY)
		{
			return;
		}

		bool isPending = false;
		int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPending);
		if (pendingOrderError == ERR_NO_ERROR && isPending)
		{
			mMBStopOrderTicket = OrderHelper::CancelPendingOrderByTicket(mMBStopOrderTicket);
		}
	}
}

bool TheSunriseShatterSingle::AllowedToTrade()
{
	return mMRFTS.OpenPrice() > 0.0 && (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= mMaxSpreadPips;
}

bool TheSunriseShatterSingle::Confirmation()
{
	bool isTrue = false;
	int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mFirstMBInSetupNumber, mMBT, isTrue);
	if (confirmationError != ERR_NO_ERROR)
	{
		mHasSetup = false;
		mStopTrading = true;
		return false;
	}

	return isTrue;
}

void TheSunriseShatterSingle::PlaceOrders()
{
	if (mMBStopOrderTicket != EMPTY)
	{
		return;
	}

	int orders = 0;
	int ordersError = OrderHelper::OtherEAOrders(mStrategyMagicNumbers, orders);
	if (ordersError != ERR_NO_ERROR)
	{
		mHasSetup = false;
		mStopTrading = true;
		return;
	}

	if (orders > mMaxTradesPerStrategy)
	{
		mHasSetup = false;
		mStopTrading = true;
		return;
	}

	int orderPlaceError = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, MagicNumber, mFirstMBInSetupNumber, mMBT, mMBStopOrderTicket);
	if (mMBStopOrderTicket == EMPTY)
	{
		mHasSetup = false;
		mStopTrading = true;
		return;
	}
}

void TheSunriseShatterSingle::CheckSetSetup()
{
	if (mHasSetup)
	{
		return;
	}

	bool isTrue = false;
	int setupError = SetupHelper::BreakAfterMinROC(mMRFTS, mMBT, isTrue);

	if (setupError == Errors::ERR_MB_DOES_NOT_EXIST)
	{
		mStopTrading = true;
		return;
	}

	if (setupError != ERR_NO_ERROR)
	{
		return;
	}

	if (!isTrue)
	{
		return;
	}

	MBState *tempMBState;
	if (!mMBT.GetNthMostRecentMB(0, tempMBState))
	{
		mStopTrading = true;
		return;
	}

	mFirstMBInSetupNumber = tempMBState.Number();
	mSetupType = tempMBState.Type();
	mHasSetup = true;
}

void TheSunriseShatterSingle::Reset()
{
	mStopTrading = false;
	mHasSetup = false;

	mMBStopOrderTicket = -1;
	mSetupType = -1;
	mFirstMBInSetupNumber = -1;
}

void TheSunriseShatterSingle::Run()
{
	mMBT.DrawNMostRecentMBs(1);
	mMBT.DrawZonesForNMostRecentMBs(1);
	mMRFTS.Draw();

	Manage();
	CheckInvalidateSetup();

	if (AllowedToTrade())
	{
		mWasReset = false;
		if (!mStopTrading)
		{
			if (mHasSetup && Confirmation())
			{
				PlaceOrders();
			}

			CheckSetSetup();
		}
	}
	else if (!mWasReset)
	{
		Reset();
		mWasReset = true;
	}
}
