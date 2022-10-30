//
//  DeckStatsWindow.h
//  KaniManabu
//
//  Created by 千代田桃 on 10/30/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckStatsWindow : NSWindowController
@property (strong) NSUUID *deckuuid;
- (void)loadChart;
@end

NS_ASSUME_NONNULL_END
