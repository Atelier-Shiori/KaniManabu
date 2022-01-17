//
//  KanaEditor.m
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/11/22.
//

#import "KanaEditor.h"
#import "AnswerCheck.h"
#import "DeckManager.h"

@interface KanaEditor ()
@property (strong) IBOutlet NSTextField *savestatus;
@property (strong) IBOutlet NSButton *savebtn;
@end

@implementation KanaEditor
- (instancetype)init {
    self = [super initWithWindowNibName:@"KanaEditor"];
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
        [self populatefromDictionary:[DeckManager.sharedInstance getCardWithCardUUID:self.cardUUID withType:DeckTypeKana]];
    }
    _notes.textColor = NSColor.controlTextColor;
}

- (bool)validateFields {
    // Check if meaning fields and reading fields have valid input
    if (![AnswerCheck validateAlphaNumericString:_englishmeaning.stringValue] && ![AnswerCheck validateAlphaNumericString:_altmeanings.stringValue] && ![AnswerCheck validateKanaNumericString:_japaneseword.stringValue] && ![AnswerCheck validateKanaNumericString:_kanareadings.stringValue]) {
        return true;
    }
    return false;
}

- (IBAction)save:(id)sender {
    if ([self validateFields]) {
        [self generateSaveDictionary];
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        [self.window close];
    }
    else {
        NSBeep();
        _savestatus.stringValue = @"Check values, invalid characters in meaning fields.";
    }
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
- (IBAction)setkanareading:(id)sender {
    _kanareadings.stringValue = _japaneseword.stringValue;
    [self textDidChange:nil];
}

- (void)populatefromDictionary:(NSDictionary *)dict {
    _japaneseword.stringValue = dict[@"japanese"];
    _englishmeaning.stringValue = dict[@"english"];
    _altmeanings.stringValue = dict[@"altmeaning"] != [NSNull null] ? dict[@"altmeaning"] : @"";
    _kanareadings.stringValue = dict[@"kanareading"];
    _notes.string = dict[@"notes"] != [NSNull null] ? dict[@"notes"] : @"";
    _contextsentence1.stringValue = dict[@"contextsentence1"] != [NSNull null] ? dict[@"contextsentence1"] : @"";
    _contextsentence2.stringValue = dict[@"contextsentence2"] != [NSNull null] ? dict[@"contextsentence2"] : @"";
    _englishsentence1.stringValue = dict[@"englishsentence1"] != [NSNull null] ? dict[@"englishsentence1"] : @"";
    _englishsentence2.stringValue = dict[@"englishsentence2"] != [NSNull null] ? dict[@"englishsentence2"] : @"";
    _tags.stringValue = dict[@"tags"] != [NSNull null] ? dict[@"tags"] : @"";
    _savebtn.enabled = YES;
}

- (void)generateSaveDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"japanese"] = _japaneseword.stringValue;
    dict[@"english"] = _englishmeaning.stringValue;
    dict[@"altmeaning"] = _altmeanings.stringValue;
    dict[@"kanareading"] = _kanareadings.stringValue;
    dict[@"notes"] = _notes.string;
    dict[@"contextsentence1"] = _contextsentence1.stringValue;
    dict[@"contextsentence2"] = _contextsentence2.stringValue;
    dict[@"englishsentence1"] = _englishsentence1.stringValue;
    dict[@"englishsentence2"] = _englishsentence2.stringValue;
    dict[@"tags"] = _tags.stringValue;
    self.cardSaveData = dict;
}


@end
