## Context

See `proposal.md`, under Why. `statisticsProvider` reads `completionsInRange(now - 365 days, now + 1 day)` and passes the logs to `computeStatistics`, which derives every card and the streak from that single list. `_streak` walks backward from today through the days that have a finished run.

## Goals / non-goals

**Goals:**

- Let you see any past week or month, and all time.
- Keep the streak meaning "your current streak" whatever period you're viewing.

**Non-goals:**

- Comparing periods side by side, or showing trends across periods.
- A user setting for the first day of the week.
- Persisting the selected period across launches. The screen always opens on the current week.

## Decisions

### A pure `StatsPeriod` value resolves to a range

`StatsPeriod` holds a kind (week, month, or all time) and an anchor date. `range(firstDayOfWeek)` returns a half-open local `[start, end)` range: weeks start on the given weekday, months start on the 1st, and all time is unbounded. `previous()`, `next()`, and `isCurrent(now)` handle navigation. The value is pure Dart, so the unit tests cover month lengths, year boundaries, and both week starts without a widget tree.

Ranges are computed in local calendar days and converted to UTC only at the storage call, the same way `_dayOf` already buckets days locally. That way, a run at 23:30 lands in the week you'd expect.

*Alternative considered:* rolling windows, such as "the last 7 days". Rejected: "last week" means a calendar week to most people, and rolling windows shift under you as days pass, so the same arrow press shows different runs on different days.

### The locale decides the week start, and the screen passes it in

The screen reads `MaterialLocalizations.of(context).firstDayOfWeekIndex` and passes it into the provider family. The provider never touches `BuildContext`.

### The streak gets its own provider

`computeStatistics` stops computing the streak. A separate `currentStreakProvider` reads recent logs ending now and calls the existing `_streak` logic, which moves to its own exported function. The finishing card reads both providers.

*Rationale:* if a past week also supplied the streak's logs, viewing last week would show a streak of zero, which reads as a judgement on today. The streak query stays bounded at a year, matching today's behavior.

### Two empty states, not one

`hasData` false for the selected period shows a compact "nothing ran this week/month" message under the period control, which stays usable. Someone with no runs at all still sees the existing full-screen mascot empty state, with no control: there's nothing to browse yet.

## Risks / trade-offs

**All time reads every log.** Logs are small and local, so this is fine at current scale. If it ever isn't, aggregating in SQL is a contained change behind the same provider.

**Locale week start can surprise a bilingual user.** Someone with an English (US) phone sees Sunday starts. That's the behavior they already get from their own calendar, so it's the least surprising choice.

**A family provider per period caches each period you visit.** Use `autoDispose` so stepping through many weeks doesn't hold every result in memory.

## Migration plan

None. Nothing persisted changes shape.
