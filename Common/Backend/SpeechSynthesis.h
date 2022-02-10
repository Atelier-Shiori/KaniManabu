//
//  SpeechSynthesis.h
//  KaniManabu
//
//  Created by 千代田桃 on 2/10/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpeechSynthesis : NSObject
@property (strong) NSManagedObjectContext *moc;
+ (instancetype)sharedInstance;
- (void)sayText:(NSString *)text;
- (void)storeSubscriptionKey:(NSString *)key;
- (NSString *)getSubscriptionKey;
- (void)removeSubscriptionKey;
@end

NS_ASSUME_NONNULL_END
