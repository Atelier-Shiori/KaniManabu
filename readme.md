# KaniManabu
KaniManu (蟹学ぶ) is a flashcard app for macOS specifically for learning Japanese. It incorporates close to the same spaced reputation system used on WaniKani. 

Requires macOS 11 Big Sur or later.

# What is different about KaniManabu compared to other SRS Flashcard software like Anki?
KaniManbu is a lot easier to use with three different card types (Kanji, Kana, and Vocab). Unlike Anki, the user needs to type in the answer for both the meaning and reading instead of seeing the back of the card and picking the difficulty. This allows the learner to reinforce their knowledge.

# Features (already implemented)
* Custom decks with three types to choose from (Kana, Kanji, and Vocab)
* Decks are saved and synced to iCloud, making them accessible across all your Macs (and eventually iOS devices). App also works offline.
* Easy to use, fully native, and macOS optimized interface (no Electron garbage)
* WaniKani style SRS review system
* Learning mode, which allow you to "learn" the cards before reviewing them. After a learning session, the newly learned cards goes into the review queue.
* Ability to lookup words from other resources (Dictionary.app, Monokakido's Dictionaries app, and online resources)
* Ability to tag cards for future reference.
* TTS support
* Browse cards by SRS stage and critical condition items (cards that are answered correctly less than 70% of the time).
* Ability to suspend cards

# Planned features
* Ability to import and export decks (CSV and KaniManabu JSON format)
* Ability to enable/disable decks
* Anki mode (see answer and click correct/incorrect button)
* Deck statistics
* Learning forecast
* Vacation Mode
* iOS/iPadOS App



# Supporting this Project
While this app is open source, the binaries are not free since time and resources (web hosting and the Apple Developer Program to distribute the app) are needed to develop the app. However, users can self-compile, but the user will need an Apple Developer account since the Core Data database is stored in iCloud, allowing users to sync their decks to all their Macs and eventually iOS devices. I will probably create a target that will remove this limitation and just allow the database to stay local.

The app will be free during Beta, but once out of beta, it will cost $4.99 as a one-time purchase and future updates are free. There will be a 14 day trial. After the trial, the user will only be able to export the data, but won't be able to use any other functions.

You can purchase [Donate](https://malupdaterosx.moe/donate/) to unlock all the features. You may also choose to support us on [Patreon](https://www.patreon.com/malupdaterosx) as well, which you can also unlock the app for free as long you remain an active patron. 

# How to Compile in XCode
Warning: This won't work if you don't have a Developer ID installed. If you don't have one, obtain one by joining the Apple Developer Program or turn off code signing.

1. Get the Source
2. Set up the CloudKit entitlement settings on your developer account
2. Type 'xcodebuild' in the terminal to build

If you are going to distribute your own version and change the name, please change the bundle identifier to something else.

# License

Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/hachidori/blob/master/License.md).
