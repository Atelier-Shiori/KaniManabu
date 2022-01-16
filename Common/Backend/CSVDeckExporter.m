//
//  CSVDeckExporter.m
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/16/22.
//

#import "CSVDeckExporter.h"
#import "DeckManager.h"
#import "CHCSVParser.h"

@implementation CSVDeckExporter
+ (void)exportDeckwithDeck:(NSManagedObject *)deck withURL:(NSURL *)url completionHandler:(void (^)(bool success)) completionHandler {
        NSArray *cards = [DeckManager.sharedInstance retrieveCardsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
        NSArray *keys;
        switch (((NSNumber *)[deck valueForKey:@"deckType"]).intValue) {
            case DeckTypeKanji:
                keys = @[@"japanese",@"english",@"altmeaning",@"kanareading",@"readingtype",@"altreading",@"notes",@"tags"];
                break;
            case DeckTypeKana:
                keys = @[@"japanese",@"english",@"altmeaning",@"kanareading",@"notes",@"contextsentence1",@"contextsentence2",@"englishsentence1",@"englishsentence2",@"tags"];
                break;
            case DeckTypeVocab:
                keys = @[@"japanese",@"english",@"altmeaning",@"kanaWord",@"reading",@"notes",@"contextsentence1",@"contextsentence2",@"contextsentence3",@"englishsentence1",@"englishsentence2",@"englishsentence3",@"tags"];
                break;
            default:
                completionHandler(false);
                return;
        }
        NSMutableArray *tmparray = [NSMutableArray new];
        for (NSDictionary *card in cards) {
            NSMutableDictionary *ncard = [NSMutableDictionary new];
            for (NSString *key in keys) {
                ncard[key] = card[key] != [NSNull null] ? card[key] : @"";
            }
            [tmparray addObject:ncard];
        }
        CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:url.path];
        [writer writeLineOfFields:keys];
        for (NSDictionary *card in tmparray) {
            [writer writeLineWithDictionary:card];
        }
        completionHandler(true);
}
@end
