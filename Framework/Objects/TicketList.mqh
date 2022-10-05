//+------------------------------------------------------------------+
//|                                                   TicketList.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Objects/ObjectList.mqh>
#include <SummitCapital/Framework/Objects/Ticket.mqh>

class TicketList : public ObjectList<Ticket>
{
public:
    TicketList();
    ~TicketList();

    void Remove(int index);
};

TicketList::TicketList()
{
}

TicketList::~TicketList()
{
    for (int i = 0; i < Size(); i++)
    {
        delete mItems[i];
    }
}

void TicketList::Remove(int index)
{
    delete mItems[index];

    Ticket *tempTicketList[];
    ArrayResize(tempTicketList, ArraySize(mItems) - 1);

    int count = 0;
    for (int i = 0; i < ArraySize(mItems); i++)
    {
        if (CheckPointer(mItems[i]) != POINTER_INVALID)
        {
            tempTicketList[count] = mItems[i];
            count += 1;
        }
    }

    // this = tempTicketList;
}