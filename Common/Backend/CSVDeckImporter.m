//
//  CSVDeckImporter.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/14/22.
//

#import "CSVDeckImporter.h"
#import "CHCSVParser.h"

@implementation CSVDeckImporter
- (instancetype)init {
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (void)loadCSVWithURL:(NSURL *)url completionHandler:(void (^)(bool success, NSArray *columnnames)) completionHandler {
    _loadedcsvdata = [NSArray arrayWithContentsOfDelimitedURL:url options:CHCSVParserOptionsUsesFirstLineAsKeys delimiter:','];
    if (!_loadedcsvdata) {
        completionHandler(false, nil);
    }
    else {
        if (_loadedcsvdata.count > 0) {
            CHCSVOrderedDictionary *dict = _loadedcsvdata[0];
            NSMutableArray *tmparray = [NSMutableArray new];
            for (NSString *key in dict.allKeys) {
                [tmparray addObject:[[NSMutableDictionary alloc] initWithDictionary:@{@"columnname" : key, @"destination" : @"Do Not Map"}] ];
            }
            completionHandler(true,tmparray);
        }
        else {
            completionHandler(false, nil);
        }
    }
}

- (void)performimportWithDeckName:(NSString *)deckname withDeckType:(int)type destinationMap:(NSArray *)map completionHandler:(void (^)(bool success)) completionHandler {
    //Set Map
    _destinationmap = map;
    NSMutableArray *tmparray = [NSMutableArray new];
    // Generate deck for importing
    for (CHCSVOrderedDictionary *card in _loadedcsvdata) {
        NSDictionary *savedata;
        switch (type) {
            case DeckTypeKanji:
                savedata = [self mapKanjiCSVData:card];
                break;
            case DeckTypeVocab:
                savedata = [self mapVocabCSVData:card];
                break;
            case DeckTypeKana:
                savedata = [self mapKanaCSVData:card];
                break;
            default:
                completionHandler(false);
                return;
        }
        if (!savedata) {
            // Invalid mapping, missing required fields, import failed
            completionHandler(false);
            return;
        }
        [tmparray addObject:savedata];
    }
    //Create deck
    DeckManager *dm = DeckManager.sharedInstance;
    dm.importing = true;
    if (![dm checkDeckExists:deckname withType:type]) {
        [dm createDeck:deckname withType:type];
        NSUUID *deckuuid = [dm getDeckUUIDWithDeckName:deckname withDeckType:type];
        for (NSDictionary *ncard in tmparray) {
            if ([dm checkCardExistsInDeckWithDeckUUID:deckuuid withJapaneseWord:ncard[@"japanese"] withType:type]) {
                continue;
            }
            [dm addCardWithDeckUUID:deckuuid withCardData:ncard withType:type];
        }
        dm.importing = false;
        // Save the data
        [dm.moc performBlockAndWait:^{
            [dm.moc save:nil];
        }];
        completionHandler(true);
    }
    else {
        completionHandler(false);
    }
}

- (NSDictionary *)mapKanjiCSVData:(NSDictionary *)card {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (NSDictionary *map in _destinationmap) {
        NSString *colstr = map[@"columnname"];
        NSString *deststr = map[@"destination"];
        if (!card[colstr]) {
            // No value, skip
            continue;
        }
        if ([deststr isEqualToString:@"Japanese"]) {
            if (!dict[@"japanese"]) {
                dict[@"japanese"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Primary Reading"]) {
            if (!dict[@"kanareading"]) {
                dict[@"kanareading"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Primary Reading Type"]) {
            if (!dict[@"readingtype"]) {
                NSString *value =  card[colstr];
                NSNumber *readingtype = @(0);
                if (([value caseInsensitiveCompare:@"on'yomi"] == NSOrderedSame) || ([value caseInsensitiveCompare:@"onyomi"] == NSOrderedSame) || ([value caseInsensitiveCompare:@"on"] == NSOrderedSame)) {
                    readingtype = @(0);
                }
                else if (([value caseInsensitiveCompare:@"kun'yomi"] == NSOrderedSame) || ([value caseInsensitiveCompare:@"kunyomi"] == NSOrderedSame) || ([value caseInsensitiveCompare:@"kun"] == NSOrderedSame)) {
                    readingtype = @(1);
                }
                dict[@"readingtype"] = readingtype;
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Reading"]) {
            if (!dict[@"altreading"]) {
                dict[@"altreading"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
    }
    if (!dict[@"japanese"] || !dict[@"english"] || !dict[@"kanareading"] || !dict[@"readingtype"]) {
        return nil;
    }
    return dict;
}

- (NSDictionary *)mapVocabCSVData:(NSDictionary *)card {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (NSDictionary *map in _destinationmap) {
        NSString *colstr = map[@"columnname"];
        NSString *deststr = map[@"destination"];
        if (!card[colstr]) {
            // No value, skip
            continue;
        }
        if ([deststr isEqualToString:@"Japanese"]) {
            if (!dict[@"japanese"]) {
                dict[@"japanese"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Kana"]) {
            if (!dict[@"kanaWord"]) {
                dict[@"kanaWord"] = [self quotesCleanup:card[colstr]];
                dict[@"reading"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 1"]) {
            if (!dict[@"contextsentence1"]) {
                dict[@"contextsentence1"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 2"]) {
            if (!dict[@"contextsentence2"]) {
                dict[@"contextsentence2"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 3"]) {
            if (!dict[@"contextsentence3"]) {
                dict[@"contextsentence3"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 1"]) {
            if (!dict[@"englishsentence1"]) {
                dict[@"englishsentence1"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 2"]) {
            if (!dict[@"englishsentence2"]) {
                dict[@"englishsentence2"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 3"]) {
            if (!dict[@"englishsentence3"]) {
                dict[@"englishsentence3"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
    }
    if (!dict[@"japanese"] || !dict[@"english"] || !dict[@"kanaWord"] || !dict[@"reading"]) {
        return nil;
    }
    return dict;
}

- (NSDictionary *)mapKanaCSVData:(NSDictionary *)card {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (NSDictionary *map in _destinationmap) {
        NSString *colstr = map[@"columnname"];
        NSString *deststr = map[@"destination"];
        if (!card[colstr]) {
            // No value, skip
            continue;
        }
        if ([deststr isEqualToString:@"Japanese"]) {
            if (!dict[@"japanese"]) {
                dict[@"japanese"] = [self quotesCleanup:card[colstr]];
                dict[@"kanareading"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 1"]) {
            if (!dict[@"contextsentence1"]) {
                dict[@"contextsentence1"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 2"]) {
            if (!dict[@"contextsentence2"]) {
                dict[@"contextsentence2"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 1"]) {
            if (!dict[@"englishsentence1"]) {
                dict[@"englishsentence1"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 2"]) {
            if (!dict[@"englishsentence2"]) {
                dict[@"englishsentence2"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = [self quotesCleanup:card[colstr]];
            }
            else {
                return nil;
            }
        }
    }
    if (!dict[@"japanese"] || !dict[@"english"] || !dict[@"kanareading"]) {
        return nil;
    }
    return dict;
}
- (NSString *)quotesCleanup:(NSString *)string {
    if (string.length > 0) {
        NSString *quotesubstr1 = [string substringWithRange:NSMakeRange(0, 1)];
        NSString *quotesubstr2 = [string substringWithRange:NSMakeRange(string.length-1, 1)];
        return [quotesubstr1 isEqualToString:@"\""] && [quotesubstr2 isEqualToString:@"\""] ? [string substringWithRange:NSMakeRange(1, string.length-2)] : string;
    }
    return string;
}
@end
