//
//  ItemInfoWindowController.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import "JapaneseWebView.h"



@interface ItemInfoWindowController : NSWindowController
@property (strong) NSUUID *cardUUID;
@property (strong) NSDictionary *cardMeta;
@property int cardType;
@property int parentWindowType;
@property (strong) JapaneseWebView * jWebView;
@property (strong) IBOutlet NSView *containerview;

typedef NS_ENUM(int,ParentWindowType) {
    ParentWindowTypeDeckBrowser = 0,
    ParentWindowTypeReview = 1
};
- (void)setDictionary:(NSDictionary *)dictionary withWindowType:(ParentWindowType)wtype;
@end


