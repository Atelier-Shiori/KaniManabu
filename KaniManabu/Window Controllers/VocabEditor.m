//
//  VocabEditor.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "VocabEditor.h"
#import "AnswerCheck.h"

@interface VocabEditor ()
@property (strong) IBOutlet NSTextField *savestatus;
@property (strong) IBOutlet NSButton *savebtn;

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
}

- (bool)validateFields {
    // Check if meaning fields and reading fields have valid input
    if (![AnswerCheck validateAlphaNumericString:_englishmeaning.stringValue] && ![AnswerCheck validateAlphaNumericString:_altmeanings.stringValue] && ![AnswerCheck validateKanaNumericString:_kana.stringValue] && ![AnswerCheck validateKanaNumericString:_kanareadings.stringValue]) {
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

- (IBAction)useKanaReadings:(id)sender {
    _kanareadings.stringValue = _kana.stringValue;
    [self textDidChange:nil];
}

- (void)textDidChange:(NSNotification *)aNotification {
    if (_japaneseword.stringValue.length > 0 && _englishmeaning.stringValue.length > 0 && _kana.stringValue.length > 0 && _kanareadings.stringValue.length > 0) {
        _savebtn.enabled = YES;
    }
    else {
        _savebtn.enabled = NO;
    }
}

- (void)generateSaveDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"japanese"] = _japaneseword.stringValue;
    dict[@"english"] = _englishmeaning.stringValue;
    dict[@"altmeaning"] = _altmeanings.stringValue;
    dict[@"kanaWord"] = _kana.stringValue;
    dict[@"reading"] = _kanareadings.stringValue;
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

@end
