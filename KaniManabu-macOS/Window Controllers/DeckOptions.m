//
//  DeckOptions.m
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/15/22.
//

#import "DeckOptions.h"
#import "DeckManager.h"

@interface DeckOptions ()
@property (strong) NSString *origname;
@end

@implementation DeckOptions

- (instancetype)init {
    self = [super initWithWindowNibName:@"DeckOptions"];
    if (!self)
        return nil;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil];
}

- (void)loadSettings:(NSManagedObject *)deckmeta {
    _deckname.stringValue = [deckmeta valueForKey:@"deckName"];
    _origname = [deckmeta valueForKey:@"deckName"];
    _deckankimode.state = ((NSNumber *)[deckmeta valueForKey:@"ankimode"]).boolValue;
    _deckenabled.state = ((NSNumber *)[deckmeta valueForKey:@"enabled"]).boolValue;
    _deckType = ((NSNumber *)[deckmeta valueForKey:@"deckType"]).intValue;
    [_newcardmode selectItemWithTag:((NSNumber *)[deckmeta valueForKey:@"newcardmode"]).intValue];
    _newcardlimit.stringValue = ((NSNumber *)[deckmeta valueForKey:@"newcardlimit"]).stringValue;
    _overridenewcardlimit.state = ((NSNumber *)[deckmeta valueForKey:@"overridenewcardlimit"]).boolValue;
}

- (IBAction)savebtn:(id)sender {
    if (![DeckManager.sharedInstance checkDeckExists:_deckname.stringValue withType:_deckType]) {
        _newsettings = @{@"deckName" : _deckname.stringValue, @"ankimode" : @(_deckankimode.state), @"enabled" : @(_deckenabled.state), @"overridenewcardlimit" : @(_overridenewcardlimit.state), @"newcardlimit" : @(_newcardlimit.stringValue.intValue), @"newcardmode" : @(_newcardmode.selectedTag)};
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        [self.window close];
    }
    else if ([_deckname.stringValue isEqualToString:_origname]) {
        _newsettings = @{@"ankimode" : @(_deckankimode.state), @"enabled" : @(_deckenabled.state), @"overridenewcardlimit" : @(_overridenewcardlimit.state), @"newcardlimit" : @(_newcardlimit.stringValue.intValue), @"newcardmode" : @(_newcardmode.selectedTag)};
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        [self.window close];
    }
    else {
        NSBeep();
    }
}
- (IBAction)cancelbtn:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}


- (void)textDidChange:(NSNotification *)aNotification {
    if (_deckname.stringValue.length > 0) {
        _savebtn.enabled = YES;
    }
    else {
        _savebtn.enabled = NO;
    }
}
@end
