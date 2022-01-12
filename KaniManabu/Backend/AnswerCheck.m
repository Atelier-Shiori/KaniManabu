//
//  AnswerCheck.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "AnswerCheck.h"
#import "string_score.h"
#import "NSString+RomajiKanaConvert.h"

@implementation AnswerCheck
NSString *const kHiraganacharacterset = @"ーぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをん";
NSString *const kHiraganaVerbCharacterset = @"うくぐすずつづぬふぶぷむる";
NSString *const kKatakanacharacterset = @"-ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶ";
NSString *const kAlphanumericcharacterset = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_, ";
double const kFuzziness = 0.3;

+ (bool)validateAlphaNumericString:(NSString *)string {
    NSCharacterSet *alphanumericset = [NSCharacterSet characterSetWithCharactersInString:kAlphanumericcharacterset];
    alphanumericset = [alphanumericset invertedSet];
    NSRange r = [string rangeOfCharacterFromSet:alphanumericset];
    if (r.location != NSNotFound) {
        return true;
    }
    return false;
}

+ (bool)validateKanaNumericString:(NSString *)string {
    NSCharacterSet *hiraganaset = [NSCharacterSet characterSetWithCharactersInString:kHiraganacharacterset];
    NSCharacterSet *katakanaset = [NSCharacterSet characterSetWithCharactersInString:kKatakanacharacterset];
    hiraganaset = [hiraganaset invertedSet];
    katakanaset = [katakanaset invertedSet];
    NSRange r1 = [string rangeOfCharacterFromSet:hiraganaset];
    NSRange r2 = [string rangeOfCharacterFromSet:katakanaset];
    if (r1.location != NSNotFound && r2.location != NSNotFound) {
        return true;
    }
    return false;
}

+ (bool)checkKanaReadingIsVerb:(NSString *)kanareading {
    // Checks if Japanese word is a verb
    NSString *lastkanastring = [kanareading substringFromIndex:kanareading.length-1];
    NSCharacterSet *hiraganaverbset = [NSCharacterSet characterSetWithCharactersInString:kHiraganaVerbCharacterset];
    hiraganaverbset = [hiraganaverbset invertedSet];
    NSRange r = [lastkanastring rangeOfCharacterFromSet:hiraganaverbset];
    if (r.location != NSNotFound) {
        return false;
    }
    return true;
}

+ (AnswerState)checkMeaning:(NSString *)answer withCard:(NSManagedObject *)card {
    // Check if answer is only alphanumeric and contains no Japanese
    if ([self validateAlphaNumericString:answer]) {
        return AnswerStateInvalidCharacters;
    }
    // Trim whitespace if any
    answer = [answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // Check Answers
    NSString *correctAnswer = [card valueForKey:@"english"];
    NSArray *altAnswers = [(NSString *)[card valueForKey:@"altmeaning"] componentsSeparatedByString:@","];
    
    if ([card valueForKey:@"japanese"] && [self checkKanaReadingIsVerb:[card valueForKey:@"japanese"]]) {
        if ([answer caseInsensitiveCompare:[correctAnswer substringFromIndex:3]] == NSOrderedSame) {
            // Answer missing "to ", required for verbs. Prompt user
            return AnswerStateVerbNoTo;
        }
        
        // Check for imprecise match with stringscore.
        float stringscore = string_fuzzy_score(answer.UTF8String, [correctAnswer substringFromIndex:3].UTF8String, kFuzziness);
        if (stringscore >= .9) {
            // Answer missing "to ", required for verbs. Prompt user
            return AnswerStateVerbNoTo;
        }
        
    }
    
    if ([answer caseInsensitiveCompare:correctAnswer] == NSOrderedSame) {
        return AnswerStatePrecise;
    }
    
    // Check for imprecise match with stringscore.
    float stringscore = string_fuzzy_score(answer.UTF8String, correctAnswer.UTF8String, kFuzziness);
    if (stringscore >= .9) {
        // Answer is correct enough, but not precise.
        return AnswerStateInprecise;
    }
    
    // Check alternative answers
    for (NSString *altAnswer in altAnswers) {
        NSString * taltAnswer = [altAnswer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([answer caseInsensitiveCompare:taltAnswer] == NSOrderedSame) {
            return AnswerStatePrecise;
        }
        // Check for imprecise match with stringscore.
        float stringscore = string_fuzzy_score(answer.UTF8String, taltAnswer.UTF8String, kFuzziness);
        if (stringscore >= .9) {
            // Answer is correct enough, but not precise.
            return AnswerStateInprecise;
        }
    }
    // Answer is incorrect
    return AnswerStateIncorrect;
}

+ (AnswerState)checkVocabReading:(NSString *)answer withCard:(NSManagedObject *)card {
    // Validate String
    if ([self validateKanaNumericString:answer]) {
        return AnswerStateInvalidCharacters;
    }
    answer = [answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // Convert answer to Hiragana
    answer = [answer stringKatakanaToHiragana];
    // Check answer
    NSString *correctAnswer = [card valueForKey:@"kanaWord"];
    if ([answer isEqualToString:correctAnswer]) {
        return AnswerStatePrecise;
    }
    // Answer is incorrect
    return AnswerStateIncorrect;
}

+ (AnswerState)checkKanjiReading:(NSString *)answer withCard:(NSManagedObject *)card {
    // Validate String
    if ([self validateKanaNumericString:answer]) {
        return AnswerStateInvalidCharacters;
    }
    answer = [answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // Convert answer to Hiragana
    answer = [answer stringKatakanaToHiragana];
    // Check alt reading
    NSArray *altAnswers = [(NSString *)[card valueForKey:@"altreading"] componentsSeparatedByString:@","];
    // Check alternative answers
    for (NSString *altAnswer in altAnswers) {
        NSString * taltAnswer = [altAnswer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([answer caseInsensitiveCompare:taltAnswer] == NSOrderedSame) {
            // We are looking for the primary reading, do not mark answer as incorrect, but prompt user to type in main meaning for the Kanji
            return AnswerStateOtherKanjiReading;
        }
    }
    // Check answer
    NSArray *correctAnswers = [(NSString *)[card valueForKey:@"kanareading"] componentsSeparatedByString:@","];
    for (NSString *correctAnswer in correctAnswers) {
        NSString * tcorrectAnswer = [correctAnswer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([answer isEqualToString:tcorrectAnswer]) {
            return AnswerStatePrecise;
        }
    }
    // Answer is incorrect
    return AnswerStateIncorrect;
}

@end
