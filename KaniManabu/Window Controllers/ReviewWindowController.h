//
//  ReviewWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>



@interface ReviewWindowController : NSWindowController <NSTextFieldDelegate,NSTableViewDelegate>
@property (strong) NSMutableArray *reviewqueue;
@property bool learnmode;
@property bool ankimode;
- (void)startReview:(NSArray *)reviewitems;
@end


