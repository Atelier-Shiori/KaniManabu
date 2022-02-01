---
title: About SRS (Spaced Repetition System)
description: This explains what SRS is and how it works.
keyword: srs,spaced repetition system,srs levels
order: -.INF
---

KaniManabu uses SRS (Spaced Repetition System). When you answer a card correctly, some time needs to past before you review the item. If you get it wrong, it will shorten the time for the next review of that card.

# SRS Levels
These are the SRS Levels in KaniManabu:
* Apprentice (1-4)
* Guru (1-2)
* Master
* Enlightened
* Burned (Card no longer reviewed, until you reset it)

These are the times you need to wait between SRS stages:
* Apprentice1 -> 2 : 4 hours
* Apprentice2 -> 3 : 8 hours
* Apprentice3 -> 4 : 1 day
* Apprentice4 -> Guru1 : 2 days
* Guru1 -> 2 : 1 week
* Guru2 -> Master : 2 weeks
* Master -> Enlightened : 1 month
* Enlightened -> Burned : 4 months

# How Next SRS stages are determined
The next SRS stage is determined by this formula.
new_srs_stage = current_srs_stage - (incorrect_adjustment_count * srs_penalty_factor)

* current_srs_stage - The current SRS stage for the card
* incorrect_adjustment_count - This is the number of cards you got incorrect divided by 2 and rounded.
* srs_penalty_factor - The factor that determines the stage deincrement. By default, it's **1**. For stages above Guru 1, the factor is **2**.
