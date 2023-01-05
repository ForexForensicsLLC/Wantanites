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

    // adds an item to the end of the list
    void Add(T item);

    // adds an item to the front of the list and pushes everything else back
    void Push(T item);

    // returns the number of elements in the list
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

template <typename T>
void List::Push(T item)
{
    T tempItems[];
    ArrayResize(tempItems, Size() + 1);

    ArrayCopy(tempItems, mItems, 1, 0);
    tempItems[0] = item;

    ArrayResize(mItems, Size() + 1);
    ArrayCopy(mItems, tempItems);
}