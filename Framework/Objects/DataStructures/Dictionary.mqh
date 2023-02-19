//+------------------------------------------------------------------+
//|                                                         Dictionary.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataStructures\List.mqh>

template <typename T, typename U>
class Dictionary
{
private:
    List<T> *mKeys;
    List<U> *mValues;

public:
    Dictionary();
    Dictionary(Dictionary<T, U> &dictionary);
    ~Dictionary();

    T operator[](int index) { return mKeys[index]; }

    T GetKey(int index) { return mKeys[index]; }
    U GetValue(int index) { return mValues[index]; }

    // adds an item to the end of the list
    void Add(T key, U value);

    // adds an item to the front of the list and pushes everything else back
    void Push(T key, U value);

    // returns the number of elements in the list
    int Size() { return mKeys.Size(); }

    // returns true if the key exists
    bool HasKey(T key);

    // returns true and sets value if the key exists, returns false otherwise
    bool GetValueByKey(T key, U &value);

    void UpdateValueForKey(T key, U value);

    // removes a key/value pair by value
    void RemoveByKey(T key);

    // WARNING: Should only be used if you know that you don't have duplicate values
    void RemoveByValue(U value);

    // removes all items from the list and re sizes to 0
    void Clear();
};

template <typename T, typename U>
Dictionary::Dictionary()
{
    mKeys = new List<T>();
    mValues = new List<U>();
}

template <typename T, typename U>
Dictionary::Dictionary(Dictionary<T, U> &dictionary)
{
    mKeys = new List<T>();
    mValues = new List<U>();

    for (int i = 0; i < dictionary.Size(); i++)
    {
        T key = dictionary[i];
        U value;

        if (dictionary.GetValueByKey(key, value))
        {
            Push(key, value);
        }
    }
}

template <typename T, typename U>
Dictionary::~Dictionary()
{
    delete mKeys;
    delete mValues;
}

template <typename T, typename U>
void Dictionary::Add(T key, U value)
{
    if (mKeys.Contains(key))
    {
        return;
    }

    mKeys.Add(key);
    mValues.Add(value);
}

template <typename T, typename U>
void Dictionary::Push(T key, U value)
{
    if (mKeys.Contains(key))
    {
        return;
    }

    mKeys.Push(key);
    mValues.Push(value);
}

template <typename T, typename U>
bool Dictionary::HasKey(T key)
{
    return mKeys.Contains(key);
}

template <typename T, typename U>
bool Dictionary::GetValueByKey(T key, U &value)
{
    int keyIndex = mKeys.IndexOf(key);
    if (keyIndex == EMPTY)
    {
        return false;
    }

    value = mValues[keyIndex];
    return true;
}

template <typename T, typename U>
void Dictionary::UpdateValueForKey(T key, U value)
{
    if (HasKey(key))
    {
        int keyIndex = mKeys.IndexOf(key);
        mValues.UpdateItem(keyIndex, value);
    }
}

template <typename T, typename U>
void Dictionary::RemoveByKey(T key)
{
    int index = mKeys.IndexOf(key);
    mKeys.RemoveByIndex(index);
    mValues.RemoveByIndex(index);
}

template <typename T, typename U>
void Dictionary::RemoveByValue(U value)
{
    int index = mValues.IndexOf(value);
    mKeys.RemoveByIndex(index);
    mValues.RemoveByIndex(index);
}

template <typename T, typename U>
void Dictionary::Clear()
{
    mKeys.Clear();
    mValues.Clear();
}