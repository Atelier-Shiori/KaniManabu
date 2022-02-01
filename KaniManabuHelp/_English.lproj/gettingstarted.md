---
title: Getting Started
description: Getting Started with KaniManabu
keyword: overview
order: -.INF
---

# What is KaniManabu?
KaniManabu is a WaniKani-style SRS app for macOS that allows users to memorize words by typing instead of viewing the card and picking a difficulty. KaniManabu has built in card types, which makes it easy for users to create their own decks without messing with templates.

# Main Interface
![Main Interface](maininterface.png)
1. **Deck Browser** - The Deck Browser allows you to browse cards from decks you have, by SRS level, and view call cards and critical items. You can manage cards in the Deck Browser.
2. **New Deck** - Creates a new deck.
3. **Import Deck** - This option allows you to import decks from a CSV file, see Importing Decks.
4. **Export Deck** - This option allows you to export a deck to a CSV file.
5. **Review Queue** - This indicates the number of cards that are in the review for a specific deck.
6. **Learning Queue** - This indicates the number of cards that are in the learning queue for a specific deck.
7. **Learn** - Starts a learning session for the deck you choose.
8. **Review** - Starts a review of cards in the review queue for the deck you choose.
9. **Add Card** - Adds a new card to the deck
10. **Delete Deck** - Deletes the deck
11. **Deck Options** - This allows you to rename the deck or set options.

## Deck Browser
![Deck Browser](deckbrowser.png)
1. **Cards** - Your cards in the deck/SRS Level/Critical Items will appear here.
2. **Add Card** - Adds a new card to the current deck (Does not apply to viewing cards by SRS Stage, All Cards, and Critical Items)
3. **Modify Card** - Modifies the current card
4. **Delete Card** - Deletes the current card
5. **Filter/Search Field** - This is the search field for the current deck. You can filter by English, Japanese, Kana readings, notes, and tags.
6. **Decks** - Your decks appear here
7. **SRS Stages** - View cards by SRS stage
8. **Critical Items** - These are cards that you answered correctly less than 70% of the time.

## Learning Mode
![Learn Mode](learnmode.png)
In learning mode, you get to preview the cards before taking a quiz on them. Once you finish the quiz, the newly learned cards goes into the review queue.

1. **Go Back/Advances** - You can advance or view the previous card in the learning queue. Once you reach the end of the queue, you can start the review quiz.
2. **Play Voice** - Plays the TTS voice of the Japanese Word (doesn't apply to Kanji)
3. **Look Up in Dictionary App** - Looks up the current word in macOS's Dictionary App.
4. **Additional Resources** - Allows you to view additional resources
5. **Japanese Word/Kanji** - The word or Kanji you are learning
6. **Informations** - this contains all the information for the current card

## Review Mode (Default)
![Review](review.png)
This is the review interface where you review items that are in the queue.

1. **Last 10 Items** - Views the list of 10 items you have reviewed in the current session
2. **Item Information** - Views the card's information. This button will enable after you answered.
3. **Review Status** - Shows current score, number of cards correct, and number of remaining cards in the queue.
4. **Japanese Word/Kanji** - This is the Japanese Word/Kanji you answering the question for
5. **Question Type** - This is what answer the card is prompting you.
6. **Answer Fields** - You type your answer what the card asked for here. If you enter invalid characters or an answer that is correct, but not what the card is asking, it will prompt you.
7. **Check Answer** - Check your answer by pressing the enter button or this button.

Note: Once you answered all the questions for a card, it will show the next SRS level.

## Review Mode (Anki Mode)
![Anki Mode](ankimode1.png)
In Anki Mode, you guess the answer on paper or in your mind and click the **Show Answer** button.
![Anki Mode](ankimode2.png)
After clicking the **Show Answer**, you select if you got the card **Correct** or **Wrong**. The next SRS level will appear above the **Correct** and **Wrong** buttons.