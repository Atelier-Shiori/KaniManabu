//
//  WaniKani.h
//  KaniManabu
//
//  Created by 千代田桃 on 1/24/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface WaniKani : NSObject
@property (strong) NSManagedObjectContext *moc;
+ (instancetype)sharedInstance;
- (void)checkToken:(NSString *)token completionHandler:(void (^)(bool success)) completionHandler;
- (void)saveToken:(NSString *)token;
- (NSString *)getToken;
- (void)removeToken;
- (void)refreshUserInformationWithcompletionHandler:(void (^)(bool success)) completionHandler;
- (void)getSubject:(NSString *)subject isKanji:(bool)isKanji completionHandler:(void (^)(bool success, bool notauthorized, NSDictionary *data)) completionHandler;
- (void)analyzeWord:(NSString *)word completionHandler:(void (^)(NSArray *data)) completionHandler;
@end
