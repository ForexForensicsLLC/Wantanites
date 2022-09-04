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
private:
public:
    PartialList();
    PartialList(PartialList &partials);
    ~PartialList();

    void Clear();
};

PartialList::PartialList()
{
}

PartialList::PartialList(PartialList &partials)
{
    for (int i = 0; i < partials.Size(); i++)
    {
        Partial *partial = new Partial(partials[i]);
        mItems[i] = partial;
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
