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
class List
{
private:
    T mItems[];

public:
    List();
    ~List();

    T operator[](int index) { return mItems[index]; }
    // void operator=(T &items[]);

    void Add(T item);
    int Size() { return ArraySize(mItems); }
};

template <typename T>
List::List()
{
}

template <typename T>
List::~List()
{
}

template <typename T>
void List::Add(T item)
{
    ArrayResize(mItems, Size() + 1);
    mItems[Size() - 1] = item;
}