//
//  LearnWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LearnWindowController : NSWindowController
@property (strong) NSArray *studyitems;
- (void)loadStudyItemsForDeckUUID:(NSUUID *)uuid withType:(int)deckType;
@end

NS_ASSUME_NONNULL_END
