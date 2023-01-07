//+------------------------------------------------------------------+
//|                                                         List.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

/**
 * @brief Create a List of Objects
 *
 * @tparam T Type of List
 * @remark The object needs to have a copy constructor defined or else it won't compile
 */
template <typename T>
class ObjectList
{
protected:
    T *mItems[];
    T *GetItemPointer(T &obj);

public:
    ObjectList();
    ObjectList(ObjectList<T> &objList);
    ~ObjectList();

    T *operator[](int index);
    void operator=(T *&items[]); // doesn't create new objects. Only use when you won't be editing the same object in different places

    int Size() { return ArraySize(mItems); }

    // adds an item to the end of the lsit
    void Add(T *&item);

    // removes an item from the list
    void Remove(int index);

    // removes all items from the list
    void Clear();

    template <typename U, typename V>
    void RemoveWhere(U locator, V value);
};

template <typename T>
ObjectList::ObjectList()
{
    ArrayResize(mItems, 0);
}

template <typename T>
ObjectList::ObjectList(ObjectList<T> &objList)
{
    for (int i = 0; i < objList.Size(); i++)
    {
        T *obj = new T(objList[i]);
        Add(obj);
    }
}

template <typename T>
ObjectList::~ObjectList()
{
    Clear();
}

template <typename T>
T *ObjectList::GetItemPointer(T &obj)
{
    return GetPointer(obj);
}

template <typename T>
T *ObjectList::operator[](int index)
{
    return GetPointer(mItems[index]);
}

template <typename T>
void ObjectList::operator=(T *&items[])
{
    ArrayResize(mItems, ArraySize(items));
    ArrayCopy(mItems, items);
}

template <typename T>
void ObjectList::Add(T *&item)
{
    ArrayResize(mItems, Size() + 1);
    mItems[Size() - 1] = item;
}

template <typename T>
void ObjectList::Remove(int index)
{
    delete this[index];

    T *tempList[];
    ArrayResize(tempList, ArraySize(mItems) - 1);

    int count = 0;
    for (int i = 0; i < ArraySize(mItems); i++)
    {
        if (CheckPointer(mItems[i]) != POINTER_INVALID)
        {
            tempList[count] = mItems[i];
            count += 1;
        }
    }

    this = tempList;
}

template <typename T>
void ObjectList::Clear()
{
    for (int i = 0; i < Size(); i++)
    {
        delete this[i];
    }

    ArrayResize(mItems, 0);
}

template <typename T>
template <typename U, typename V>
void ObjectList::RemoveWhere(U locator, V value)
{
    for (int i = 0; i < Size(); i++)
    {
        if (locator(this[i], value))
        {
            Remove(i);
        }
    }
}