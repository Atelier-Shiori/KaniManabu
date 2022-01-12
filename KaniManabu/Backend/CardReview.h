//
//  CardReview.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SRScheduler.h"

NS_ASSUME_NONNULL_BEGIN

@interface CardReview : NSObject
typedef NS_ENUM(int,CardType) {
    CardTypeKanji = 0,
    CardTypeVocab = 1,
    CardTypeKana = 2
};

typedef NS_ENUM(int,CardReviewType) {
    CardReviewTypeMeaning = 0,
    CardReviewTypeReading = 1
};

@property (strong) NSManagedObject* card;
@property bool learningmode;
@property int cardtype;
@property bool reviewed;
@property bool reviewedreading;
@property bool reviewedmeaning;
@property int currentreviewnumincorrect;
@property bool currentreviewmeaningincorrect;
@property bool currentreviewreadingincorrect;
@property int proposedSRSStage;
- (instancetype)initWithCard:(NSManagedObject *)card withCardType:(int)type;
- (void)setCorrect:(CardReviewType)reviewtype;
- (void)setIncorrect:(CardReviewType)reviewtype;
- (void)finishReview;
- (void)suspendReview;
@end

NS_ASSUME_NONNULL_END
