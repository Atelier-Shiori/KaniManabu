//
//  SRSLevelValueTransformer.h
//  KaniManabu
//
//  Created by 千代田桃 on 1/11/22.
//

#import <Foundation/Foundation.h>



@interface SRSLevelValueTransformer : NSValueTransformer
+ (Class)transformedValueClass;
- (id)transformedValue:(nullable id)value;
@end


