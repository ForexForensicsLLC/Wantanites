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

    // adds an item to the end of the list
    void Add(T item);

    // adds an item to the front of the list and pushes everything else back
    void Push(T item);

    // adds an item to a specific index of the list and pushes everything else back
    void Insert(int index, T item);

    // returns the number of elements in the list
    int Size() { return ArraySize(mItems); }

    bool IsEmpty() { return Size() == 0; }

    // returns true if the item is in the list
    bool Contains(T item);

    int IndexOf(T item);

    void UpdateItem(int index, T item);

    void RemoveByIndex(int index);

    // removes all items from the list and re sizes to 0
    void Clear();
};

template <typename T>
List::List()
{
}

template <typename T>
List::~List()
{
    Clear();
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

template <typename T>
void List::Insert(int index, T item)
{
    if (index > Size())
    {
        Print("Index ", IntegerToString(index), " does not exist. Size: ", Size());
        return;
    }

    if (Size() == 0 || index == Size())
    {
        Add(item);
        return;
    }

    int itemsToCopy = Size() - index - 1;

    T tempItems[];
    ArrayResize(tempItems, itemsToCopy);

    ArrayCopy(tempItems, mItems, 0, index + 1, itemsToCopy);

    ArrayResize(mItems, Size() + 1);
    Print("Index: ", index, ", Size: ", Size());
    mItems[index] = item;

    ArrayCopy(mItems, tempItems, index + 1, 0, itemsToCopy);
}

template <typename T>
bool List::Contains(T item)
{
    for (int i = 0; i < Size(); i++)
    {
        if (mItems[i] == item)
        {
            return true;
        }
    }

    return false;
}

template <typename T>
int List::IndexOf(T item)
{
    for (int i = 0; i < Size(); i++)
    {
        if (mItems[i] == item)
        {
            return i;
        }
    }

    return ConstantValues::EmptyInt;
}

template <typename T>
void List::UpdateItem(int index, T item)
{
    if (index >= Size())
    {
        return;
    }

    mItems[index] = item;
}

template <typename T>
void List::RemoveByIndex(int index)
{
    T tempItems[];
    ArrayResize(tempItems, Size() - 1);

    ArrayCopy(tempItems, mItems, 0, 0, index); // don't add or subtrace since this is count not index
    ArrayCopy(tempItems, mItems, index, index + 1, Size() - index);

    ArrayResize(mItems, Size() - 1);
    ArrayCopy(mItems, tempItems);
}

template <typename T>
void List::Clear()
{
    ArrayFree(mItems);
}