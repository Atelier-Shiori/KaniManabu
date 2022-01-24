//
//  WaniKani.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/24/22.
//

#import "WaniKani.h"
#import <AFNetworking/AFNetworking.h>
#import <SAMKeychain/SAMKeychain.h>

@interface WaniKani ()
@property (strong) AFHTTPSessionManager *manager;
@end

@implementation WaniKani

NSString *const kKanacharacterset = @"ーぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをん、-ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶ";

+ (instancetype)sharedInstance {
    static WaniKani *wsharedManager = nil;
    static dispatch_once_t waniKanitoken;
    dispatch_once(&waniKanitoken, ^{
        wsharedManager = [WaniKani new];
    });
    return wsharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.manager = [AFHTTPSessionManager manager];
        self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        ((AFJSONResponseSerializer *)self.manager.responseSerializer).acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return self;
}

- (void)checkToken:(NSString *)token completionHandler:(void (^)(bool success)) completionHandler {
    [_manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [_manager GET:@"https://api.wanikani.com/v2/user" parameters:@{} headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(true);
    }];
}

- (void)saveToken:(NSString *)token {
    [SAMKeychain setPassword:token forService:@"KaniManabu" account:@"WaniKani API Key"];
}

- (NSString *)getToken {
    return [SAMKeychain passwordForService:@"KaniManabu" account:@"WaniKani API Key"];
}

- (void)removeToken {
    [SAMKeychain deletePasswordForService:@"KaniManabu" account:@"WaniKani API Key"];
    [NSUserDefaults.standardUserDefaults setValue:@"" forKey:@"WaniKaniUsername"];
    [NSUserDefaults.standardUserDefaults setValue:@"" forKey:@"WaniKaniSubscribed"];
}

- (void)refreshUserInformationWithcompletionHandler:(void (^)(bool success)) completionHandler {
    NSString *token = [self getToken];
    if (token) {
        if (token.length > 0) {
            [_manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [_manager GET:@"https://api.wanikani.com/v2/user" parameters:@{} headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [NSUserDefaults.standardUserDefaults setValue:responseObject[@"data"][@"username"] forKey:@"WaniKaniUsername"];
                [NSUserDefaults.standardUserDefaults setValue:responseObject[@"data"][@"subscription"][@"active"] forKey:@"WaniKaniSubscribed"];
                completionHandler(true);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                completionHandler(false);
            }];
        }
        else {
            completionHandler(false);
            return;
        }
    }
    else {
        completionHandler(false);
    }
}

- (void)getSubject:(NSString *)subject isKanji:(bool)isKanji completionHandler:(void (^)(bool success, bool notauthorized, NSDictionary *data)) completionHandler {
    NSManagedObject *subjectobj = [self retrieveSubject:subject isKanji:isKanji];
    if (subjectobj) {
        double lastupdated = ((NSNumber *)[subjectobj valueForKey:@"lastupdated"]).doubleValue;
        if ([NSDate dateWithTimeIntervalSince1970:lastupdated].timeIntervalSinceNow > -604800) {
            NSError *jsonError;
            NSData *objectData = [[subjectobj valueForKey:@"jsondata"] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                  options:NSJSONReadingMutableContainers
                                                    error:&jsonError];
            if (![NSUserDefaults.standardUserDefaults boolForKey:@"WaniKaniSubscribed"]) {
                if (((NSNumber *)json[@"data"][@"level"]).intValue >= 4) {
                    // User not subscribed, don't return information
                    completionHandler(false, true, nil);
                    return;
                }
                else {
                    completionHandler(true, false, json);
                    return;
                }
            }
            else {
                completionHandler(true,false, json);
                return;
            }
        }
    }
    [_manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getToken]] forHTTPHeaderField:@"Authorization"];
    [_manager GET:@"https://api.wanikani.com/v2/subjects" parameters:@{@"types" : isKanji ? @"kanji" : @"vocabulary", @"slugs" : subject} headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *data = responseObject[@"data"];
        if (data.count > 0) {
            NSDictionary *subdata = data[0];
            if (![NSUserDefaults.standardUserDefaults boolForKey:@"WaniKaniSubscribed"]) {
                if (((NSNumber *)subdata[@"data"][@"level"]).intValue >= 4) {
                    // User not subscribed, don't return information
                    completionHandler(false, true, nil);
                }
            }
            else {
                // Save data
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:subdata
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&error];

                if (! jsonData) {
                    NSLog(@"Got an error: %@", error);
                    completionHandler(false, false, nil);
                } else {
                    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    NSManagedObject *subjectobj = [self retrieveSubject:subject isKanji:isKanji];
                    if (!subjectobj) {
                        subjectobj = isKanji ? [NSEntityDescription insertNewObjectForEntityForName:@"Subjects" inManagedObjectContext:self.moc] : [NSEntityDescription insertNewObjectForEntityForName:@"VocabSubjects" inManagedObjectContext:self.moc];
                        [subjectobj setValue:subject forKey:@"slug"];
                    }
                    [subjectobj setValue:jsonString forKey:@"jsondata"];
                    [subjectobj setValue:@(NSDate.date.timeIntervalSince1970) forKey:@"lastupdated"];
                    __block NSError *serror = nil;
                    [self.moc performBlockAndWait:^{
                        [self.moc save:&serror];
                        if (error) {
                            NSLog(@"Error: %@", error.localizedDescription);
                        }
                    }];
                    completionHandler(true,false,subdata);
                }
            }
        }
        else {
            completionHandler(false, false, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(false, false, nil);
    }];
}

- (NSManagedObject *)retrieveSubject:(NSString *)slug isKanji:(bool)isKanji {
    @try { [_moc setQueryGenerationFromToken:NSQueryGenerationToken.currentQueryGenerationToken error:nil];} @catch (NSException *ex) {}
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = isKanji ? [NSEntityDescription entityForName:@"Subjects" inManagedObjectContext:_moc] : [NSEntityDescription entityForName:@"VocabSubjects" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slug == %@",slug];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *tmparray = [_moc executeFetchRequest:fetchRequest error:&error];
    if (tmparray.count > 0) {
        return tmparray[0];
    }
    return nil;
}

- (void)analyzeWord:(NSString *)word completionHandler:(void (^)(NSArray *data)) completionHandler {
    NSCharacterSet *kanaset = [NSCharacterSet characterSetWithCharactersInString:kKanacharacterset];
    NSString *KanjiOnlyString = [[word componentsSeparatedByCharactersInSet:kanaset] componentsJoinedByString:@""];
    NSMutableArray *seperatedKanjis = [NSMutableArray new];
    for (int i = 0; i < KanjiOnlyString.length; i++) {
        NSString *substr = [KanjiOnlyString substringWithRange:NSMakeRange(i, 1)];
        for (NSString *kanji in seperatedKanjis) {
            if ([kanji isEqualToString:substr]) {
                continue;
            }
        }
        [seperatedKanjis addObject:substr];
    }
    __block bool done = false;
    __block int currentkanjiindex = 0;
    NSMutableArray *kanjiData = [NSMutableArray new];
    for (NSString *kanjistr in seperatedKanjis) {
        [self getSubject:kanjistr isKanji:true completionHandler:^(bool success, bool notauthorized, NSDictionary *data) {
            if (success && !notauthorized) {
                [kanjiData addObject:data];
            }
            currentkanjiindex++;
            if (currentkanjiindex == seperatedKanjis.count) {
                done = true;
            }
        }];
    }
    while (!done) {
        sleep(1);
    }
    completionHandler(kanjiData);
}
@end
