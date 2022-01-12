//
//  ItemInfoWindowController.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ItemInfoWindowController : NSWindowController
@property (strong) NSUUID *cardUUID;
@property (strong) NSDictionary *cardMeta;
@property int cardType;
@property int parentWindowType;

typedef NS_ENUM(int,ParentWindowType) {
    ParentWindowTypeDeckBrowser = 0,
    ParentWindowTypeReview = 1
};
- (void)setDictionary:(NSDictionary *)dictionary withWindowType:(ParentWindowType)wtype;
@end

NS_ASSUME_NONNULL_END
