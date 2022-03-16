//
//  SpeechSynthesis.h
//  KaniManabu
//
//  Created by 千代田桃 on 2/10/22.
//
#import <TargetConditionals.h>
#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpeechSynthesis : NSObject
@property (strong) NSManagedObjectContext *moc;
typedef NS_ENUM(int,TTSService) {
    TTSMicrosoft = 0,
    TTSIBM = 1
};
+ (instancetype)sharedInstance;
- (void)sayText:(NSString *)text;
- (void)storeSubscriptionKey:(NSString *)key;
- (NSString *)getSubscriptionKey;
- (void)removeSubscriptionKey;
- (void)storeIBMAPIKey:(NSDictionary *)data;
- (NSDictionary *)getIBMAPIKey;
- (void)removeIBMAPIKey;
- (void)playSample;
@end

NS_ASSUME_NONNULL_END
