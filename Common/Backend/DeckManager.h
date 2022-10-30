//
//  DeckManager.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DeckManager : NSObject
@property (strong) NSManagedObjectContext *moc;
@property bool importing;
typedef NS_ENUM(int,DeckType) {
    DeckTypeKanji = 0,
    DeckTypeVocab = 1,
    DeckTypeKana = 2
};

typedef NS_ENUM(int,NewCardReviewMode) {
    OldCardsFirst = 0,
    NewCardsFirst = 1,
    NewCardsRandom = 2
};

+ (instancetype)sharedInstance;
- (bool)createDeck:(NSString *)deckname withType:(int)type;
- (bool)checkDeckExists:(NSString *)deckname withType:(int)type;
- (bool)deleteDeckWithDeckUUID: (NSUUID *)uuid;
- (NSArray *)retrieveReviewItemsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)retrieveAllReviewItems;
- (NSUUID *)getDeckUUIDWithDeckName:(NSString *)deckname withDeckType:(DeckType)type;
- (long)getQueuedReviewItemsCountforUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)setandretrieveLearnItemsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)setandretrieveLearnItemsForDeckUUID:(NSUUID *)uuid withType:(int)type learningmore:(bool)learningmore;
- (void)setLearnDateForDeckUUID:(NSUUID *)uuid setToday:(bool)today;
- (NSDate *)getLearnDateForDeckUUID: (NSUUID *)uuid;
- (long)getQueuedLearnItemsCountforUUID:(NSUUID *)uuid withType:(int)type;
- (long)getNotLearnedItemCountForUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)getAllLearnItems;
- (NSArray *)retrieveCardsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)retrieveAllCardswithPredicate:(NSPredicate *)predicates;
- (NSArray *)retrieveAllCriticalCards;
- (NSArray *)retrieveDecks;
- (NSManagedObject *)getDeckMetadataWithUUID:(NSUUID *)uuid;
- (bool)addCardWithDeckUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type;
- (bool)modifyCardWithCardUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type;
- (bool)checkCardExistsInDeckWithDeckUUID:(NSUUID *)uuid withJapaneseWord:(NSString *)word withType:(DeckType)type;
- (NSDictionary *)getCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type;
- (bool)deleteCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type;
- (void)deleteAllCardsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (void)resetCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type;
- (void)resetCardToEnlightenedWithCardUUID:(NSUUID *)uuid withType:(DeckType)type ;
- (void)togglesuspendCardForCardUUID:(NSUUID *)uuid withType:(int)type;
- (void)removeOrphanedCards;
- (bool)checkiCloudLoggedIn;
- (NSDictionary *)generateForecastDataforDeckUUID:(NSUUID *)uuid;
- (NSDictionary *)generateLearnedChartDataforDeckUUID:(NSUUID *)uuid;
- (NSDictionary *)generateSRSChartDataforDeckUUID:(NSUUID *)uuid;
@end


