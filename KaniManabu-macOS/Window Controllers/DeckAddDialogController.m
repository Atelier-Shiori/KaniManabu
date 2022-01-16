//
//  DeckAddDialogController.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "DeckAddDialogController.h"

@interface DeckAddDialogController ()
@property (strong) IBOutlet NSButton *createbtn;

@end

@implementation DeckAddDialogController
- (instancetype)init {
    self = [super initWithWindowNibName:@"NewDeckDialog"];
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

- (IBAction)createDeck:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    [self.window close];
}

- (IBAction)cancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}

- (void)textDidChange:(NSNotification *)aNotification {
    if (_deckname.stringValue.length > 0) {
        _createbtn.enabled = YES;
    }
    else {
        _createbtn.enabled = NO;
    }
}

@end
