//+------------------------------------------------------------------+
//|                                                     EAInitHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Helpers\OrderInfoHelper\OrderInfoHelper.mqh>

class EAInitHelper
{
public:
    static bool CheckSymbolAndTimeFrame(string expectedSymbol, int expectedTimeFrame);
    static bool HasLicenses(LicenseManager *&lm);

    template <typename TEA>
    static void FindSetPreviousAndCurrentSetupTickets(TEA &ea);
    template <typename TEA, typename TRecord>
    static void UpdatePreviousSetupTicketsRRAcquried(TEA &ea);
    template <typename TEA, typename TRecord>
    static void SetPreviousSetupTicketsOpenData(TEA &ea);
};

static bool EAInitHelper::CheckSymbolAndTimeFrame(string expectedSymbol, int expectedTimeFrame)
{
    if (StringFind(Symbol(), expectedSymbol) == -1)
    {
        Print("Incorrect Symbol: ", Symbol(), ". Expected: ", expectedSymbol);
        return false;
    }

    if (Period() != expectedTimeFrame)
    {
        Print("Incorrect Time Frame: ", Period(), ". Expected: ", expectedTimeFrame);
        return false;
    }

    return true;
}

static bool EAInitHelper::HasLicenses(LicenseManager *&lm)
{
    bool allFinished = false;
    bool hasLicenses = lm.HasAllLicenses(allFinished);
    if (!hasLicenses && allFinished)
    {
        ExpertRemove();
    }

    return hasLicenses;
}

template <typename TEA>
static void EAInitHelper::FindSetPreviousAndCurrentSetupTickets(TEA &ea)
{
    ea.mLastState = EAStates::SETTING_ACTIVE_TICKETS;

    int tickets[];
    int findTicketsError = OrderInfoHelper::FindActiveTicketsByMagicNumber(false, ea.MagicNumber(), tickets);
    if (findTicketsError != Errors::NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, findTicketsError);
    }

    for (int i = 0; i < ArraySize(tickets); i++)
    {
        Ticket *ticket = new Ticket(tickets[i]);
        ticket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);

        if (ea.MoveToPreviousSetupTickets(ticket))
        {
            ea.mPreviousSetupTickets.Add(ticket);
        }
        else
        {
            ea.mCurrentSetupTickets.Add(ticket);
        }
    }
}

template <typename TEA, typename TRecord>
static void EAInitHelper::UpdatePreviousSetupTicketsRRAcquried(TEA &ea)
{
    if (ea.mPreviousSetupTickets.Size() == 0)
    {
        return;
    }

    TRecord *record = new TRecord();

    ea.mPartialCSVRecordWriter.SeekToStart();
    while (!FileIsEnding(ea.mPartialCSVRecordWriter.FileHandle()))
    {
        record.ReadRow(ea.mPartialCSVRecordWriter.FileHandle());
        if (record.MagicNumber != ea.MagicNumber())
        {
            continue;
        }

        for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
        {
            // check for both in case the ticket was partialed more than once
            // only works with up to 2 partials
            if (record.TicketNumber == ea.mPreviousSetupTickets[i].Number() || record.NewTicketNumber == ea.mPreviousSetupTickets[i].Number())
            {
                ea.mPreviousSetupTickets[i].mPartials.RemoveWhere<TPartialRRLocator, double>(Partial::FindPartialByRR, record.ExpectedPartialRR);
                break;
            }
        }
    }

    delete record;
}

template <typename TEA, typename TRecord>
static void EAInitHelper::SetPreviousSetupTicketsOpenData(TEA &ea)
{
    if (ea.mPreviousSetupTickets.IsEmpty() && ea.mCurrentSetupTickets.IsEmpty())
    {
        return;
    }

    TRecord *record = new TRecord();
    bool foundCurrent = false;

    ea.mEntryCSVRecordWriter.SeekToStart();
    while (!FileIsEnding(ea.mEntryCSVRecordWriter.FileHandle()))
    {
        record.ReadRow(ea.mEntryCSVRecordWriter.FileHandle());

        // needed for dynamic risk calculations
        if (record.AccountBalanceBefore > ea.mLargestAccountBalance)
        {
            ea.mLargestAccountBalance = record.AccountBalanceBefore;
        }

        if (record.MagicNumber != ea.MagicNumber())
        {
            continue;
        }

        bool foundTicket = false;
        for (int i = 0; i < ea.mCurrentSetupTickets.Size(); i++)
        {
            if (record.TicketNumber == ea.mCurrentSetupTickets[i].Number())
            {
                // ea.mCurrentSetupTickets[i].OpenPrice(record.EntryPrice);
                // ea.mCurrentSetupTickets[i].OpenTime(record.EntryTime);
                // ea.mCurrentSetupTickets[i].LotSize(record.Lots);
                ea.mCurrentSetupTickets[i].OriginalStopLoss(record.OriginalStopLoss);

                foundTicket = true;
                break;
            }
        }

        if (foundTicket)
        {
            continue;
        }

        for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
        {
            if (record.TicketNumber == ea.mPreviousSetupTickets[i].Number())
            {
                // ea.mPreviousSetupTickets[i].OpenPrice(record.EntryPrice);
                // ea.mPreviousSetupTickets[i].OpenTime(record.EntryTime);
                // ea.mPreviousSetupTickets[i].LotSize(record.Lots);
                ea.mPreviousSetupTickets[i].OriginalStopLoss(record.OriginalStopLoss);

                break;
            }
        }
    }

    delete record;
}