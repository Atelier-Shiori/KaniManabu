//
//  DeckOptions.h
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/15/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckOptions : NSWindowController
@property (strong) NSUUID *deckuuid;
@property int deckType;
@property (strong) IBOutlet NSTextField *deckname;
@property (strong) IBOutlet NSButton *deckenabled;
@property (strong) IBOutlet NSButton *deckankimode;
@property (strong) IBOutlet NSButton *savebtn;
@property (strong) NSDictionary *newsettings;
@property (strong) IBOutlet NSButton *overridenewcardlimit;
@property (strong) IBOutlet NSTextField *newcardlimit;
@property (strong) IBOutlet NSPopUpButton *newcardmode;
- (void)loadSettings:(NSManagedObject *)deckmeta;
@end

NS_ASSUME_NONNULL_END
