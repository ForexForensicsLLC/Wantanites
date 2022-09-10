//+------------------------------------------------------------------+
//|                                                         List.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

template <typename T>
class ObjectList
{
protected:
    T mItems[];

public:
    ObjectList();
    ~ObjectList();

    T operator[](int index);
    void operator=(T &items[]); // doesn't create new objects. Only use when you won't be editing the same object in different places

    void Add(T &item);
    int Size() { return ArraySize(mItems); }
};

template <typename T>
T ObjectList::operator[](int index)
{
    return mItems[index];
}

template <typename T>
ObjectList::ObjectList()
{
    ArrayResize(mItems, 0);
}

template <typename T>
ObjectList::~ObjectList()
{
}

template <typename T>
void ObjectList::Add(T &item)
{
    ArrayResize(mItems, Size() + 1);
    mItems[Size() - 1] = item;
}

template <typename T>
void ObjectList::operator=(T &items[])
{
    ArrayResize(mItems, ArraySize(items));
    ArrayCopy(mItems, items);
}
