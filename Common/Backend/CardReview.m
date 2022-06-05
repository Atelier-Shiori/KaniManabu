//
//  CardReview.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "CardReview.h"

@implementation CardReview
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)initWithCard:(NSManagedObject *)card withCardType:(int)type {
    if (self = [self init]) {
        self.card = card;
        self.cardtype = type;
        self.proposedSRSStage = ((NSNumber *)[_card valueForKey:@"srsstage"]).intValue;
        if (((NSNumber *)[_card valueForKey:@"inreview"]).boolValue) {
            self.proposedSRSStage = ((NSNumber *)[_card valueForKey:@"proposedsrsstage"]).intValue;
            self.currentreviewnumincorrect = ((NSNumber *)[_card valueForKey:@"reviewincorrectcount"]).intValue;
            self.currentreviewmeaningincorrect = ((NSNumber *)[_card valueForKey:@"reviewincorrectmeaning"]).boolValue;
            self.currentreviewmeaningincorrect = ((NSNumber *)[_card valueForKey:@"reviewincorrectreading"]).boolValue;
            self.reviewedreading = ((NSNumber *)[_card valueForKey:@"reviewedreading"]).boolValue;
            self.reviewedmeaning = ((NSNumber *)[_card valueForKey:@"reviewedmeaning"]).boolValue;
        }
        if (self.cardtype == CardTypeKana) {
            // Kana card type is meaning only. Set the reading review state to true
            self.reviewedreading = true;
        }
    }
    return self;
}

- (instancetype)initWithConjCard:(ConjugationReviewCard *)ccard {
    if (self = [self init]) {
        self.ccard = ccard;
        self.cardtype = CardTypeConjugReview;
        self.proposedSRSStage = 0;
    }
    return self;
}

- (void)setCorrect:(CardReviewType)reviewtype {
    switch (reviewtype) {
        case CardReviewTypeMeaning: {
            int meaningcorrectcount = ((NSNumber *)[_card valueForKey:@"nummeaningcorrect"]).intValue;
            [self.card setValue:@(meaningcorrectcount+1) forKey:@"nummeaningcorrect"];
            self.reviewedmeaning = true;
            break;
        }
        case CardReviewTypeReading: {
            int readingcorrectcount = ((NSNumber *)[_card valueForKey:@"nummeaningcorrect"]).intValue;
            [self.card setValue:@(readingcorrectcount+1) forKey:@"numreadingcorrect"];
            self.reviewedreading = true;
            break;
        }
        case CardReviewTypeAnswerOnly: {
            // For Misc cards and Conjugation practice only
            if (_cardtype == CardTypeMisc) {
                int correctcount = ((NSNumber *)[_card valueForKey:@"numansweredcorrect"]).intValue;
                [self.card setValue:@(correctcount+1) forKey:@"numansweredcorrect"];
            }
            self.reviewedanswer = true;
        }
        default: {
            break;
        }
    }
    if (((self.reviewedreading && self.reviewedmeaning && !self.currentreviewmeaningincorrect && !self.currentreviewreadingincorrect) && (_cardtype != CardTypeMisc || _cardtype != CardTypeConjugReview)) || ((self.reviewedanswer && !self.currentreviewanswerincorrect) && (_cardtype == CardTypeMisc || _cardtype == CardTypeConjugReview))) {
        _proposedSRSStage = [SRScheduler newStageByIncrementingCurrentStage:self.proposedSRSStage];
    }
}

- (void)setIncorrect:(CardReviewType)reviewtype {
    // Set the incorrect state for review type, only once
    switch (reviewtype) {
        case CardReviewTypeMeaning: {
            if (!self.currentreviewmeaningincorrect) {
                if (!_learningmode) {
                    // Only increment the incorrect count when the card is learned
                    int meaningincorrectcount = ((NSNumber *)[_card valueForKey:@"nummeaningincorrect"]).intValue;
                    [self.card setValue:@(meaningincorrectcount+1) forKey:@"nummeaningincorrect"];
                }
                self.currentreviewmeaningincorrect = true;
            }
            break;
        }
        case CardReviewTypeReading: {
            if (!self.currentreviewreadingincorrect) {
                if (!_learningmode) {
                    // Only increment the incorrect count when the card is learned
                    int readingincorrectcount = ((NSNumber *)[_card valueForKey:@"numreadingincorrect"]).intValue;
                    [self.card setValue:@(readingincorrectcount+1) forKey:@"numreadingincorrect"];
                }
                self.currentreviewreadingincorrect = true;
            }
            break;
        }
        case CardTypeMisc: {
            if (!self.currentreviewanswerincorrect) {
                if (!_learningmode) {
                    // Only increment the incorrect count when the card is learned
                    int answerincorrectcount = ((NSNumber *)[_card valueForKey:@"numanswerincorrect"]).intValue;
                    [self.card setValue:@(answerincorrectcount+1) forKey:@"numanswerincorrect"];
                }
                self.currentreviewanswerincorrect = true;
            }
            break;
        }
        case CardTypeConjugReview: {
            self.currentreviewanswerincorrect = true;
            break;
        }
        default: {
            break;
        }
    }
    // Increment current incorrect review count for the card and recalculate proposed SRS stage.
    self.currentreviewnumincorrect++;
    if (!_learningmode) {
        // Only decreate SRS stage when the card is not in learning mode. SRS stage cannot be 0.
        _proposedSRSStage = [SRScheduler calculatedDeIncrementSRSStageWithCurrentStage:_proposedSRSStage withIncorrectCount:_currentreviewnumincorrect];
        if (_proposedSRSStage <= 0) {
            _proposedSRSStage = 1;
        }
    }
    else {
        _proposedSRSStage = 1;
    }
}

- (void)finishReview {
    self.reviewed = true;
    if (_cardtype == CardTypeConjugReview) {
        // No need to write review progress for Conjugation practice items since they aren't real cards
        return;
    }
    if (self.currentreviewnumincorrect == 0) {
        // Increment Correct count
        int correctcount = ((NSNumber *)[_card valueForKey:@"numansweredcorrect"]).intValue;
        [self.card setValue:@(correctcount+1) forKey:@"numansweredcorrect"];
    }
    else {
        // Increment Incorrect count, only for learned cards
        if (!_learningmode) {
            int incorrectcount = ((NSNumber *)[_card valueForKey:@"numansweredincorrect"]).intValue;
            [self.card setValue:@(incorrectcount+1) forKey:@"numansweredincorrect"];
        }
    }
    // Set new SRS Stage
    [_card setValue:@(_proposedSRSStage) forKey:@"srsstage"];
    // Reset in review values
    [_card setValue:@(0) forKey:@"proposedsrsstage"];
    if (_cardtype == CardTypeMisc) {
        [_card setValue:@(0) forKey:@"reviewincorrectcount"];
        [_card setValue:@NO forKey:@"reviewincorrectanswer"];
        [_card setValue:@NO forKey:@"reviewedanswer"];
    }
    else {
        [_card setValue:@(0) forKey:@"reviewincorrectcount"];
        [_card setValue:@NO forKey:@"reviewincorrectmeaning"];
        [_card setValue:@NO forKey:@"reviewincorrectreading"];
        [_card setValue:@NO forKey:@"reviewedreading"];
        [_card setValue:@NO forKey:@"reviewedmeaning"];
    }
    [_card setValue:@NO forKey:@"inreview"];
    if (_learningmode) {
        // Card is learned, set learned flag
        [_card setValue:@YES forKey:@"learned"];
        [_card setValue:@NO forKey:@"learning"];
    }
    // Set Next Review Date and last reviewed date
    NSDate *newDate = [SRScheduler getNewReviewDateWithCurrentSRSStage:self.proposedSRSStage];
    [_card setValue:@(newDate.timeIntervalSince1970) forKey:@"nextreviewinterval"];
    [_card setValue:@(NSDate.date.timeIntervalSince1970) forKey:@"lastreviewed"];
    
}

- (void)suspendReview {
    // Save the current review data to allow user to resume where they left off.
    if (!_reviewed) {
        [_card setValue:@(self.proposedSRSStage) forKey:@"proposedsrsstage"];
        [_card setValue:@(self.currentreviewnumincorrect) forKey:@"reviewincorrectcount"];
        [_card setValue:@(self.currentreviewmeaningincorrect) forKey:@"reviewincorrectmeaning"];
        [_card setValue:@(self.currentreviewreadingincorrect) forKey:@"reviewincorrectreading"];
        [_card setValue:@(self.reviewedreading) forKey:@"reviewedreading"];
        [_card setValue:@(self.reviewedmeaning) forKey:@"reviewedmeaning"];
        [_card setValue:@YES forKey:@"inreview"];
    }
}
@end
