//+------------------------------------------------------------------+
//|                                                  PartialList.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Partial.mqh>
#include <SummitCapital\Framework\Objects\ObjectList.mqh>

class PartialList : public ObjectList<Partial *>
{
public:
    PartialList();
    PartialList(PartialList &partials);
    ~PartialList();

    void Clear();
    void Remove(int index);
    void RemovePartialRR(double rr);
};

PartialList::PartialList()
{
}

PartialList::PartialList(PartialList &partials)
{
    for (int i = 0; i < partials.Size(); i++)
    {
        Partial *partial = new Partial(partials[i]);
        Add(partial);
    }
}

PartialList::~PartialList()
{
    for (int i = 0; i < Size(); i++)
    {
        delete mItems[i];
    }
}

void PartialList::Clear()
{
    for (int i = 0; i < Size(); i++)
    {
        delete mItems[i];
    }

    ArrayResize(mItems, 0);
}

void PartialList::Remove(int index)
{
    delete mItems[index];

    Partial *tempPartialList[];
    ArrayResize(tempPartialList, ArraySize(mItems) - 1);

    int count = 0;
    for (int i = 0; i < ArraySize(mItems); i++)
    {
        if (CheckPointer(mItems[i]) != POINTER_INVALID)
        {
            tempPartialList[count] = mItems[i];
            count += 1;
        }
    }

    this = tempPartialList;
}

void PartialList::RemovePartialRR(double rr)
{
    for (int i = 0; i < Size(); i++)
    {
        if (mItems[i].mRR == rr)
        {
            Remove(i);
            return;
        }
    }
}
