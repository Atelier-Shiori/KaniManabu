//
//  VocabEditor.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "VocabEditor.h"
#import "AnswerCheck.h"
#import "DeckManager.h"
#import "WaniKani.h"

@interface VocabEditor ()
@property (strong) IBOutlet NSTextField *savestatus;
@property (strong) IBOutlet NSButton *savebtn;
@property (strong) IBOutlet NSImageView *existsonwanikani;

@end

@implementation VocabEditor
- (instancetype)init {
    self = [super initWithWindowNibName:@"VocabEditor"];
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
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nil];
    if (!_newcard) {
        [self populatefromDictionary:[DeckManager.sharedInstance getCardWithCardUUID:self.cardUUID withType:DeckTypeVocab]];
    }
    _notes.textColor = NSColor.controlTextColor;
}

- (bool)validateFields {
    // Check if meaning fields and reading fields have valid input
    if (![AnswerCheck validateAlphaNumericString:_englishmeaning.stringValue] && ![AnswerCheck validateAlphaNumericString:_altmeanings.stringValue] && ![AnswerCheck validateKanaNumericString:_kana.stringValue]) {
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
    if (_japaneseword.stringValue.length > 0 && _englishmeaning.stringValue.length > 0 && _kana.stringValue.length > 0) {
        _savebtn.enabled = YES;
    }
    else {
        _savebtn.enabled = NO;
    }
}
- (void)textDidEndEditing:(NSNotification *)notification {
    NSTextField *tfield = (NSTextField *)notification.object;
    if ([tfield.identifier isEqualToString:@"japaneseword"]) {
        [self checkVocabExistsonWaniKani];
    }
}

- (void)populatefromDictionary:(NSDictionary *)dict{
    _japaneseword.stringValue = dict[@"japanese"];
    _englishmeaning.stringValue = dict[@"english"];
    _altmeanings.stringValue = dict[@"altmeaning"] != [NSNull null] ? dict[@"altmeaning"] : @"";
    _kana.stringValue = dict[@"kanaWord"];
    _notes.string = dict[@"notes"] != [NSNull null] ? dict[@"notes"] : @"";
    _contextsentence1.stringValue = dict[@"contextsentence1"] != [NSNull null] ? dict[@"contextsentence1"] : @"";
    _contextsentence2.stringValue = dict[@"contextsentence2"] != [NSNull null] ? dict[@"contextsentence2"] : @"";
    _contextsentence3.stringValue = dict[@"contextsentence3"] != [NSNull null] ? dict[@"contextsentence3"] : @"";
    _englishsentence1.stringValue = dict[@"englishsentence1"] != [NSNull null] ? dict[@"englishsentence1"] : @"";
    _englishsentence2.stringValue = dict[@"englishsentence2"] != [NSNull null] ? dict[@"englishsentence2"] : @"";
    _englishsentence3.stringValue = dict[@"englishsentence3"] != [NSNull null] ? dict[@"englishsentence3"] : @"";
    _tags.stringValue = dict[@"tags"] != [NSNull null] ? dict[@"tags"] : @"";
    _savebtn.enabled = YES;
    [self checkVocabExistsonWaniKani];
}

- (void)generateSaveDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"japanese"] = _japaneseword.stringValue;
    dict[@"english"] = _englishmeaning.stringValue;
    dict[@"altmeaning"] = _altmeanings.stringValue;
    dict[@"kanaWord"] = _kana.stringValue;
    dict[@"reading"] = _kana.stringValue;
    dict[@"notes"] = _notes.string;
    dict[@"contextsentence1"] = _contextsentence1.stringValue;
    dict[@"contextsentence2"] = _contextsentence2.stringValue;
    dict[@"contextsentence3"] = _contextsentence3.stringValue;
    dict[@"englishsentence1"] = _englishsentence1.stringValue;
    dict[@"englishsentence2"] = _englishsentence2.stringValue;
    dict[@"englishsentence3"] = _englishsentence3.stringValue;
    dict[@"tags"] = _tags.stringValue;
    self.cardSaveData = dict;
}

- (void)checkVocabExistsonWaniKani {
    if ([WaniKani.sharedInstance getToken]) {
        [WaniKani.sharedInstance getSubject:_japaneseword.stringValue isKanji:NO completionHandler:^(bool success, bool notauthorized, NSDictionary *data) {
            if (success && !notauthorized) {
                if (data) {
                    self.existsonwanikani.hidden = NO;
                }
                else {
                    self.existsonwanikani.hidden = YES;
                }
            }
            else {
                self.existsonwanikani.hidden = YES;
            }
        }];
    }
}

@end
