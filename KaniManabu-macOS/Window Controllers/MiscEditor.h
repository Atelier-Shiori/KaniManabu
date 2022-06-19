//
//  MiscEditor.h
//  KaniManabu
//
//  Created by 千代田桃 on 5/31/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MiscEditor : NSWindowController
@property (strong) IBOutlet NSTextView *questiontextview;


@property (strong) NSDictionary *cardSaveData;
@property (strong) NSUUID *deckUUID;
@property (strong) NSUUID *cardUUID;
@property bool newcard;
@end

NS_ASSUME_NONNULL_END
