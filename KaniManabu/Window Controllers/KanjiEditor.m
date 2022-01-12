//
//  KanjiEditor.m
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/11/22.
//

#import "KanjiEditor.h"

@interface KanjiEditor ()
@property (strong) IBOutlet NSTextField *savestatus;
@property (strong) IBOutlet NSButton *savebtn;
@end

@implementation KanjiEditor
- (instancetype)init {
    self = [super initWithWindowNibName:@"KanjiEditor"];
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

- (void)generateSaveDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"japanese"] = _japaneseword.stringValue;
    dict[@"english"] = _englishmeaning.stringValue;
    dict[@"altmeaning"] = _altmeanings.stringValue;
    dict[@"kanareading"] = _kanareadings.stringValue;
    dict[@"altreading"] = _altkanareadings.stringValue;
    dict[@"notes"] = _notes.string;
    dict[@"tags"] = _tags.stringValue;
    self.cardSaveData = dict;
}
- (IBAction)togglemainreadingoption:(id)sender {
    if (_mainon.state == NSControlStateValueOn) {
        _mainkun.state = NSControlStateValueOff;
        _altkun.state = NSControlStateValueOff;
    }
    else {
        _mainon.state = NSControlStateValueOff;
        _alton.state = NSControlStateValueOn;
    }
}
- (IBAction)togglealtreadingoption:(id)sender {
    if (_alton.state == NSControlStateValueOn) {
        _altkun.state = NSControlStateValueOff;
        _mainkun.state = NSControlStateValueOff;
    }
    else {
        _alton.state = NSControlStateValueOff;
        _mainon.state = NSControlStateValueOn;
    }
}

@end
