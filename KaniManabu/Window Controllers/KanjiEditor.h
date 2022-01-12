//
//  KanjiEditor.h
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/11/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface KanjiEditor : NSWindowController
@property (strong) IBOutlet NSTextField *japaneseword;
@property (strong) IBOutlet NSTextField *englishmeaning;
@property (strong) IBOutlet NSTextField *altmeanings;
@property (strong) IBOutlet NSTextField *kanareadings;
@property (strong) IBOutlet NSButton *mainon;
@property (strong) IBOutlet NSButton *mainkun;
@property (strong) IBOutlet NSTextField *altkanareadings;
@property (strong) IBOutlet NSButton *alton;
@property (strong) IBOutlet NSButton *altkun;
@property (strong) IBOutlet NSTextView *notes;
@property (strong) IBOutlet NSTextField *tags;
@property (strong) NSDictionary *cardSaveData;
@property (strong) NSUUID *deckUUID;
@property (strong) NSUUID *cardUUID;
@property bool newcard;
@end

NS_ASSUME_NONNULL_END
