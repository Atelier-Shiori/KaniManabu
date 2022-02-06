//
//  SRScheduler.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>



@interface SRScheduler : NSObject
/*
 These are the wait times for each stage
 Apprentice1 -> 2 : 4 hours
 Apprentice2 -> 3 : 8 hours
 Apprentice3 -> 4 : 1 day
 Apprentice4 -> Guru1 : 2 days
 Guru1 -> 2 : 1 week
 Guru2 -> Master : 2 weeks
 Master -> Enloghtened : 1 month
 Enlightened -> Burned : 4 months
 see https://knowledge.wanikani.com/wanikani/srs-stages/
 If user fails to answer the question in learning session, the wait time is 2 hours instead of immediately
 */
typedef NS_ENUM(int,SRSTimings) {
    SRSApprentice1 = 7200,
    SRSApprentice2 = 14400,
    SRSApprentice3 = 28800,
    SRSApprentice4 = 86400,
    SRSGuru1 = 172800,
    SRSGuru2 = 345600,
    SRSMaster = 864000,
    SRSEnlightened = 3456000
};
/*
 These are the SRS Stages enumerated
 */
typedef NS_ENUM(int,SRSStages) {
    SRSStageApprentice0 = 0,
    SRSStageApprentice1 = 1,
    SRSStageApprentice2 = 2,
    SRSStageApprentice3 = 3,
    SRSStageApprentice4 = 4,
    SRSStageGuru1 = 5,
    SRSStageGuru2 = 6,
    SRSStageMaster = 7,
    SRSStageEnlightened = 8,
    SRSStageBurned = 9
};

+ (int)calculatedDeIncrementSRSStageWithCurrentStage:(int)currentSRSStage withIncorrectCount:(long)numincorrect;
+ (int)newStageByIncrementingCurrentStage:(int)currentSRSStage;
+ (NSDate *)getNewReviewDateWithCurrentSRSStage:(int)currentSRSStage;
+ (NSString *)getSRSStageNameWithCurrentSRSStage:(int)currentSRSStage;
@end


