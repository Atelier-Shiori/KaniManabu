# KaniManabu
KaniManu (蟹学ぶ) is an open source flashcard app for macOS (and soon iOS/iPadOS) specifically for learning Japanese. It incorporates close to the same spaced reputation system used on WaniKani. 

Requires macOS 10.15 Catalina or later.

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
* TTS support (macOS and Microsoft TTS)
* Browse cards by SRS stage and critical condition items (cards that are answered correctly less than 70% of the time).
* Ability to suspend cards
* Ability to import and export decks (CSV format)
* Ability to view critical items (cards that are answered less than 70% correct)
* Anki mode (see answer and click correct/incorrect button)
* Ability to enable/disable decks
* Ability to reset cards to the first SRS level
* WaniKani integration (view information of kanji used in words in item info/lesson sessions and check if the vocab exists on Wanikani before adding. (Note that free users are limited to content available in levels 1-3)
* Ability to learn more items and set per deck new card limit

# Planned features
* Ability to import and export decks (KaniManabu JSON format)
* Ability to review all items in the queue (Review and Learning)
* Deck statistics
* Learning forecast
* Vacation Mode
* iOS/iPadOS App
* Flashy animations to show when the answer is correct.
* English -> Japanese mode
* EPWing support for autofilling words for vocab card creation (EPWing dictionaries will not be included)


# Supporting this Project
While this app is open source and libre software, the binaries are not free since time and resources (web hosting and the Apple Developer Program to distribute the app) are needed to develop the app. However, users can self-compile, but the user will need an Apple Developer account since the Core Data database is stored in iCloud, allowing users to sync their decks to all their Macs and eventually iOS devices. You need a membership to use the iCloud features with your own apps.

The app will only be available on the App Store on release and non-app store version will be for active patrons only. The free version will be limited to 3 decks and there will be some features that will be exclusive to the pro version (Microsoft/IBM Watson TTS without API key, public decks, and more). The pro version will be available through a yearly subscription of $9.99 or a lifetime subscription of $34.99. Active patrons can unlock these features with the non-app store version. The Pro version will work on both the iOS and Mac version as I plan to make it a universal purchase. I know some people hate subscriptions, but the subscription model allows me to cover infrastructure and development costs. The source code will be free for those who want to compile the app and use it for free without iCloud features.

You may also choose to support us on [Patreon](https://www.patreon.com/malupdaterosx) as well, which you can also unlock the app for free as long you remain an active patron. 

# How to Compile in XCode
Warning: This won't work if you don't have a Developer ID installed. If you don't have one, obtain one by joining the Apple Developer Program or turn off code signing.

1. Get the Source
2. Set up the CloudKit entitlement settings on your developer account
3. Download the [Microsoft Cognitive Services Speech](https://aka.ms/csspeech/iosbinary) framework. Unzip and move the MicrosoftCognitiveServicesSpeech.xcframework to the Dependencies folder.
4. Type 'xcodebuild' in the terminal to build

If you are going to distribute your own version and change the name, please change the bundle identifier to something else.

# License

Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/hachidori/blob/master/License.md).
