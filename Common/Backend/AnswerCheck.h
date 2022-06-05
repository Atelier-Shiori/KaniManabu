//
//  AnswerCheck.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ConjugationReviewCard.h"

@interface AnswerCheck : NSObject
typedef NS_ENUM(int,AnswerState) {
    AnswerStatePrecise = 0,
    AnswerStateInprecise = 1,
    AnswerStateOtherKanjiReading = 2,
    AnswerStateInvalidCharacters = 3,
    AnswerStateIncorrect = 4,
    AnswerStateVerbNoTo = 5,
    AnswerStateJapaneseReadingAnswer = 6
};
+ (bool)validateAlphaNumericString:(NSString *)string;
+ (bool)validateKanaNumericString:(NSString *)string;
+ (AnswerState)checkMeaning:(NSString *)answer withCard:(NSManagedObject *)card;
+ (AnswerState)checkVocabReading:(NSString *)answer withCard:(NSManagedObject *)card;
+ (AnswerState)checkKanjiReading:(NSString *)answer withCard:(NSManagedObject *)card;
+ (AnswerState)checkMiscAnswer:(NSString *)answer withCard:(NSManagedObject *)card;
+ (AnswerState)checkConjugation:(NSString *)answer withCard:(ConjugationReviewCard *)card;
@end


