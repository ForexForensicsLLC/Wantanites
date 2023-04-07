//+------------------------------------------------------------------+
//|                                                         SortedDictionary.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>

template <typename T, typename U>
class SortedDictionary : public Dictionary<T, U>
{
private:
public:
    SortedDictionary();
    SortedDictionary(SortedDictionary<T, U> &dictionary);
    ~SortedDictionary();

    // adds an item to the end of the list
    virtual bool Add(T key, U value);

    // adds an item to the front of the list and pushes everything else back
    virtual void Push(T key, U value);
};

template <typename T, typename U>
SortedDictionary::SortedDictionary() : Dictionary()
{
}

template <typename T, typename U>
SortedDictionary::SortedDictionary(SortedDictionary<T, U> &dictionary) : Dictionary(dictionary)
{
}

template <typename T, typename U>
SortedDictionary::~SortedDictionary()
{
}

template <typename T, typename U>
bool SortedDictionary::Add(T key, U value)
{
    if (mKeys.Contains(key))
    {
        return false;
    }

    int index = 0;
    while (index < Size() && key > mKeys[index])
    {
        index += 1;
    }

    mKeys.Insert(index, key);
    mValues.Insert(index, value);

    return true;
}

template <typename T, typename U>
void SortedDictionary::Push(T key, U value)
{
    Add(key, value);
}