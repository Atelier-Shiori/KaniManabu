//
//  LearnWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import "JapaneseWebView.h"


@interface LearnWindowController : NSWindowController
@property (strong) NSArray *studyitems;
@property bool ankimode;
@property (strong) JapaneseWebView * jWebView;
@property (strong) IBOutlet NSView *containerview;
- (void)loadStudyItemsForDeckUUID:(NSUUID *)uuid withType:(int)deckType;
@end


