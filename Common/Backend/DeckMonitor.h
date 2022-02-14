//
//  DeckMonitor.h
//  KaniManabu
//
//  Created by 千代田桃 on 2/14/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckMonitor : NSObject
@property bool syncinginprogress;
@property long previousdeckcount;
@property long totalcardcount;
@property long totalreviewqueuecount;
@property long totallearnqueuecount;
- (void)setCardTotals;
@end

NS_ASSUME_NONNULL_END
