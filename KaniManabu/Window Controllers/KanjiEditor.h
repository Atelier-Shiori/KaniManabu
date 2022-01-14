//
//  KanjiEditor.h
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/11/22.
//

#import <Cocoa/Cocoa.h>



@interface KanjiEditor : NSWindowController
@property (strong) IBOutlet NSTextField *japaneseword;
@property (strong) IBOutlet NSTextField *englishmeaning;
@property (strong) IBOutlet NSTextField *altmeanings;
@property (strong) IBOutlet NSTextField *kanareadings;
@property (strong) IBOutlet NSTextField *altkanareadings;
@property (strong) IBOutlet NSTextView *notes;
@property (strong) IBOutlet NSTextField *tags;
@property (strong) NSDictionary *cardSaveData;
@property (strong) NSUUID *deckUUID;
@property (strong) NSUUID *cardUUID;
@property bool newcard;
@end


