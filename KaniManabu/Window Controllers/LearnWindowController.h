//
//  LearnWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>



@interface LearnWindowController : NSWindowController
@property (strong) NSArray *studyitems;
- (void)loadStudyItemsForDeckUUID:(NSUUID *)uuid withType:(int)deckType;
@end


