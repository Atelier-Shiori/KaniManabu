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
    if (![dm checkDeckExists:deckname withType:type]) {
        [dm createDeck:deckname withType:type];
        NSUUID *deckuuid = [dm getDeckUUIDWithDeckName:deckname withDeckType:type];
        for (NSDictionary *ncard in tmparray) {
            if ([dm checkCardExistsInDeckWithDeckUUID:deckuuid withJapaneseWord:ncard[@"japanese"] withType:type]) {
                continue;
            }
            [dm addCardWithDeckUUID:deckuuid withCardData:ncard withType:type];
        }
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
                dict[@"japanese"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Primary Reading"]) {
            if (!dict[@"kanareading"]) {
                dict[@"kanareading"] = card[colstr];
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
                dict[@"altreading"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = card[colstr];
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
                dict[@"japanese"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Kana"]) {
            if (!dict[@"kanaWord"]) {
                dict[@"kanaWord"] = card[colstr];
                dict[@"reading"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 1"]) {
            if (!dict[@"contextsentence1"]) {
                dict[@"contextsentence1"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 2"]) {
            if (!dict[@"contextsentence2"]) {
                dict[@"contextsentence2"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 3"]) {
            if (!dict[@"contextsentence3"]) {
                dict[@"contextsentence3"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 1"]) {
            if (!dict[@"englishsentence1"]) {
                dict[@"englishsentence1"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 2"]) {
            if (!dict[@"englishsentence2"]) {
                dict[@"englishsentence2"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 3"]) {
            if (!dict[@"englishsentence3"]) {
                dict[@"englishsentence3"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = card[colstr];
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
                dict[@"japanese"] = card[colstr];
                dict[@"kanareading"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English"]) {
            if (!dict[@"english"]) {
                dict[@"english"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Alt Meanings"]) {
            if (!dict[@"altmeaning"]) {
                dict[@"altmeaning"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Notes"]) {
            if (!dict[@"notes"]) {
                dict[@"notes"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 1"]) {
            if (!dict[@"contextsentence1"]) {
                dict[@"contextsentence1"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Context Sentence 2"]) {
            if (!dict[@"contextsentence2"]) {
                dict[@"contextsentence2"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 1"]) {
            if (!dict[@"englishsentence1"]) {
                dict[@"englishsentence1"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"English Sentence 2"]) {
            if (!dict[@"englishsentence2"]) {
                dict[@"englishsentence2"] = card[colstr];
            }
            else {
                return nil;
            }
        }
        else if ([deststr isEqualToString:@"Tags"]) {
            if (!dict[@"tags"]) {
                dict[@"tags"] = card[colstr];
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
@end
