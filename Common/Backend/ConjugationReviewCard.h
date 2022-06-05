//
//  ConjugationReviewCard.h
//  KaniManabu
//
//  Created by 千代田桃 on 5/31/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConjugationReviewCard : NSObject
@property (strong) NSString *origword;
@property (strong) NSString *answerkanji;
@property (strong) NSString *answerkana;
@property (strong) NSString *questionname;
@property (strong) NSString *conjugationtype;
@end

NS_ASSUME_NONNULL_END
