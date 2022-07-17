//+------------------------------------------------------------------+
//|                                                DoubleMBSetUp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Setup.mqh>

template <typename T>
class DoubleMBSetUp
{
private:
string mDoubleMBMessage;

public:
   DoubleMBSetUp();
   ~DoubleMBSetUp();
   
   void Call();
};
template <typename T>
DoubleMBSetUp::DoubleMBSetUp()
{
   mDoubleMBMessage = "Here";
}
template <typename T>
DoubleMBSetUp::~DoubleMBSetUp()
{
}

template <typename T>
void DoubleMBSetUp::Call()
{
   Print(mDoubleMBMessage);
}