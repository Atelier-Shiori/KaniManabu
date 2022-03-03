//
//  KanaEditor.h
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/11/22.
//

#import <Cocoa/Cocoa.h>



@interface KanaEditor : NSWindowController
@property (strong) IBOutlet NSTextField *japaneseword;
@property (strong) IBOutlet NSTextField *englishmeaning;
@property (strong) IBOutlet NSTextField *altmeanings;
@property (strong) IBOutlet NSTextView *notes;
@property (strong) IBOutlet NSTextField *contextsentence1;
@property (strong) IBOutlet NSTextField *englishsentence1;
@property (strong) IBOutlet NSTextField *contextsentence2;
@property (strong) IBOutlet NSTextField *englishsentence2;
@property (strong) IBOutlet NSTextField *tags;
@property (strong) NSDictionary *cardSaveData;
@property (strong) NSUUID *deckUUID;
@property (strong) NSUUID *cardUUID;
@property bool newcard;
- (void)populatefromDictionary:(NSDictionary *)dict;
@end


