//
//  ReviewWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReviewWindowController : NSWindowController
@property (strong) NSMutableArray *reviewqueue;
- (void)startReview:(NSArray *)reviewitems;
@end

NS_ASSUME_NONNULL_END
