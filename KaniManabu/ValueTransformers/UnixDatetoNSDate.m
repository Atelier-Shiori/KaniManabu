//
//  UnixDatetoNSDate.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/11/22.
//

#import "UnixDatetoNSDate.h"

@implementation UnixDatetoNSDate
+ (Class)transformedValueClass {
    return [NSDate class];
}

- (id)transformedValue:(nullable id)value {
    if (!value) return [NSDate dateWithTimeIntervalSince1970:0];
    
    if ([value isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:((NSNumber *)value).doubleValue];
    }
    return [NSDate dateWithTimeIntervalSince1970:0];
}
@end
