//
//  CardReview.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SRScheduler.h"
#import "ConjugationReviewCard.h"



@interface CardReview : NSObject
typedef NS_ENUM(int,CardType) {
    CardTypeKanji = 0,
    CardTypeVocab = 1,
    CardTypeKana = 2,
    CardTypeMisc = 3,
    CardTypeConjugReview = 4
};

typedef NS_ENUM(int,CardReviewType) {
    CardReviewTypeMeaning = 0,
    CardReviewTypeReading = 1,
    CardReviewTypeAnswerOnly = 2
};

@property (strong) NSManagedObject* card;
@property (strong) ConjugationReviewCard *ccard;
@property bool learningmode;
@property int cardtype;
@property bool reviewed;
@property bool reviewedreading;
@property bool reviewedmeaning;
@property bool reviewedanswer;
@property int currentreviewnumincorrect;
@property bool currentreviewmeaningincorrect;
@property bool currentreviewreadingincorrect;
@property bool currentreviewanswerincorrect;
@property int proposedSRSStage;
- (instancetype)initWithCard:(NSManagedObject *)card withCardType:(int)type;
- (instancetype)initWithConjCard:(ConjugationReviewCard *)ccard;
- (void)setCorrect:(CardReviewType)reviewtype;
- (void)setIncorrect:(CardReviewType)reviewtype;
- (void)finishReview;
- (void)suspendReview;
@end


