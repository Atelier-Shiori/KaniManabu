//
//  Conjugator.h
//  conjugator
//
//  Created by 千代田桃 on 5/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Conjugator : NSObject
- (NSDictionary *)getTypesDictionary;
- (NSDictionary *)conjugateWord:(NSString *)word;
@end

NS_ASSUME_NONNULL_END
