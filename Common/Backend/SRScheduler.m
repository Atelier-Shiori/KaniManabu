//
//  SRScheduler.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import "SRScheduler.h"

@implementation SRScheduler

+ (int)calculatedDeIncrementSRSStageWithCurrentStage:(int)currentSRSStage withIncorrectCount:(long)numincorrect {
    /*
     The increment is calcuated with this forumula. Numbers are rounded up
     new_srs_stage = current_srs_stage - (incorrect_adjustment_count * srs_penalty_factor)
     See: https://knowledge.wanikani.com/wanikani/srs-stages/
     */
    int srspenaltyfactor = currentSRSStage >= 4 ? 2 : 1;
    int incorrectadjustmentcount = round(numincorrect/2);
    int newstage = currentSRSStage - (incorrectadjustmentcount * srspenaltyfactor);
    if (newstage < 0) {
        // New SRS stage can't be negative, set it as Apprentice 2 (1)
        newstage = 1;
    }
    return newstage;
}

+ (int)newStageByIncrementingCurrentStage:(int)currentSRSStage {
    return currentSRSStage + 1;
}

+ (NSDate *)getNewReviewDateWithCurrentSRSStage:(int)currentSRSStage {
    NSDate *today = [NSDate date];
    int newinterval = 0;
    switch (currentSRSStage) {
        case SRSStageApprentice0:
        case SRSStageApprentice1:
            newinterval = SRSApprentice2;
        case SRSStageApprentice2:
            newinterval = SRSApprentice3;
            break;
        case SRSStageApprentice3:
            newinterval = SRSApprentice4;
            break;
        case SRSStageApprentice4:
            newinterval = SRSGuru1;
            break;
        case SRSStageGuru1:
            newinterval = SRSGuru2;
            break;
        case SRSStageGuru2:
            newinterval = SRSMaster;
            break;
        case SRSStageMaster:
            newinterval = SRSEnlightened;
            break;
        case SRSStageEnlightened:
            newinterval = SRSBurned;
            break;
        case SRSStageBurned:
        default:
            return nil;
    }
    return [today dateByAddingTimeInterval:newinterval];
}

+ (NSString *)getSRSStageNameWithCurrentSRSStage:(int)currentSRSStage {
    switch (currentSRSStage) {
        case SRSStageApprentice1:
        case SRSStageApprentice2:
        case SRSStageApprentice3:
        case SRSStageApprentice4:
            return @"Apprentice";
        case SRSStageGuru1:
        case SRSStageGuru2:
            return @"Guru";
        case SRSStageMaster:
            return @"Master";
        case SRSStageEnlightened:
            return @"Enlightened";
        case SRSStageBurned:
            return @"Burned";
        default:
            break;
    }
    return @"Apprentice";
}
@end
