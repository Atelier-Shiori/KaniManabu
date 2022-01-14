//
//  DeckManager.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckManager : NSObject
@property (strong) NSManagedObjectContext *moc;

typedef NS_ENUM(int,DeckType) {
    DeckTypeKanji = 0,
    DeckTypeVocab = 1,
    DeckTypeKana = 2
};

+ (instancetype)sharedInstance;
- (bool)createDeck:(NSString *)deckname withType:(int)type;
- (bool)checkDeckExists:(NSString *)deckname withType:(int)type;
- (bool)deleteDeckWithDeckUUID: (NSUUID *)uuid;
- (NSArray *)retrieveReviewItemsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (NSUUID *)getDeckUUIDWithDeckName:(NSString *)deckname withDeckType:(DeckType)type;
- (long)getQueuedReviewItemsCountforUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)setandretrieveLearnItemsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (void)setLearnDateForDeckUUID:(NSUUID *)uuid setToday:(bool)today;
- (NSDate *)getLearnDateForDeckUUID: (NSUUID *)uuid;
- (long)getQueuedLearnItemsCountforUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)retrieveCardsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (NSArray *)retrieveAllCardswithType:(int)type withPredicate:(NSPredicate *)predicates;
- (NSArray *)retrieveAllCriticalCardswithType:(int)type;
- (NSArray *)retrieveDecks;
- (NSManagedObject *)getDeckMetadataWithUUID:(NSUUID *)uuid;
- (bool)addCardWithDeckUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type;
- (bool)modifyCardWithCardUUID:(NSUUID *)uuid withCardData:(NSDictionary *)cardData withType:(DeckType)type;
- (bool)checkCardExistsInDeckWithDeckUUID:(NSUUID *)uuid withJapaneseWord:(NSString *)word withType:(DeckType)type;
- (NSDictionary *)getCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type;
- (bool)deleteCardWithCardUUID:(NSUUID *)uuid withType:(DeckType)type;
- (void)deleteAllCardsForDeckUUID:(NSUUID *)uuid withType:(int)type;
- (void)togglesuspendCardForCardUUID:(NSUUID *)uuid withType:(int)type;
@end

NS_ASSUME_NONNULL_END
