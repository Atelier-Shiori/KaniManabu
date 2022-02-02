---
title: Importing Decks
description: About Importing Decks
keyword: importing, csv, importing decks
order: -.INF
---
KaniManabu allows you to import decks as long the file is in a CSV (Comma Seperated Values) in a UTF-8 format. JIS encoding is not supported.

# Mapping Fields
When you select a CSV file, besides typing a name for the new deck or using an existing deck, you need to map the CSV columns to the fields. This will differ depending on the deck type. Note that you cannot have two columns mapped to the same fields.

Also, the following fields are required, depending on deck type. If they aren't mapped, the import will fail.
Kana: Japanese and English
Vocabulary: Japanese, English, and Kana Reading
Kanji: Japanese, English, On'yomi, Primary Reading (integer value. 0 for On'yomi and 1 for Kun'yomi)

KaniManabu supports alternate readings and meanings. For Japanese, they should be seperated by the Ideographic Comma (、). For English alternate meanings, use a comma. Otherwise, alternate readings or meanings as answers won't work as attended.

Lastly, Notes allow for HTML for additional formatting. The extra formatting will parse when you view the card or learn them.
