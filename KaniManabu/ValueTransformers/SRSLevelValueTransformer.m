//
//  SRSLevelValueTransformer.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/11/22.
//

#import "SRSLevelValueTransformer.h"
#import "SRScheduler.h"

@implementation SRSLevelValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(nullable id)value {
    if (!value) return @"Unknown";
    
    if ([value isKindOfClass:[NSNumber class]]) {
        return [SRScheduler getSRSStageNameWithCurrentSRSStage:((NSNumber *)value).intValue];
    }
    return @"Unknown";
}
@end
