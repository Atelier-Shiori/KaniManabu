//
//  MiscEditor.m
//  KaniManabu
//
//  Created by 千代田桃 on 5/31/22.
//

#import "MiscEditor.h"
#import "DeckManager.h"

@interface MiscEditor ()
@property (strong) IBOutlet NSTextField *savestatus;
@property (strong) IBOutlet NSButton *savebtn;
@end

@implementation MiscEditor
- (instancetype)init {
    self = [super initWithWindowNibName:@"MiscEditor"];
    if (!self)
        return nil;
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil];
    if (!_newcard) {
        [self populatefromDictionary:[DeckManager.sharedInstance getCardWithCardUUID:self.cardUUID withType:DeckTypeKanji]];
    }
    _notes.textColor = NSColor.controlTextColor;
}

- (IBAction)save:(id)sender {
    [self generateSaveDictionary];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    [self.window close];
}

- (IBAction)cancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}

- (void)textDidChange:(NSNotification *)aNotification {
    if (_japaneseword.stringValue.length > 0 && _englishmeaning.stringValue.length > 0 && _kanareadings.stringValue.length > 0) {
        _savebtn.enabled = YES;
    }
    else {
        _savebtn.enabled = NO;
    }
}

- (void)populatefromDictionary:(NSDictionary *)dict {
    _japaneseword.stringValue = dict[@"japanese"];
    _englishmeaning.stringValue = dict[@"english"];
    _altmeanings.stringValue = dict[@"altmeaning"] != [NSNull null] ? dict[@"altmeaning"] : @"";
    _kanareadings.stringValue = dict[@"kanareading"];
    [_mainreadingtype selectItemWithTag:((NSNumber *)dict[@"readingtype"]).intValue];
    _altkanareadings.stringValue = dict[@"altreading"] != [NSNull null] ? dict[@"altreading"] : @"";
    _notes.string = dict[@"notes"] != [NSNull null] ? dict[@"notes"] : @"";
    _tags.stringValue = dict[@"tags"] != [NSNull null] ? dict[@"tags"] : @"";
    _savebtn.enabled = YES;
}

- (void)generateSaveDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"japanese"] = _japaneseword.stringValue;
    dict[@"english"] = _englishmeaning.stringValue;
    dict[@"altmeaning"] = _altmeanings.stringValue;
    dict[@"kanareading"] = _kanareadings.stringValue;
    dict[@"readingtype"] = @(_mainreadingtype.selectedTag);
    dict[@"altreading"] = _altkanareadings.stringValue;
    dict[@"notes"] = _notes.string;
    dict[@"tags"] = _tags.stringValue;
    self.cardSaveData = dict;
}
@end

