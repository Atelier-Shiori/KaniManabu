//
//  CSVImportController.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/14/22.
//

#import "CSVImportController.h"
#import "CSVDeckImporter.h"
#import "DeckManager.h"
#if defined(AppStore)
#else
#import "LicenseManager.h"
#endif

@interface CSVImportController ()

@end

@implementation CSVImportController

- (instancetype)init {
    self = [super initWithWindowNibName:@"CSVImportController"];
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
    [self loadDeckPopup];
    if (![self checkDeckLimit:true]) {
        _useexistingdeckoption.enabled = false;
        _useexistingdeckoption.state = true;
        [self setDeckPopup];
        _deckname.enabled = false;
    }
}

- (void)loadDeckPopup {
    [_importdeck.menu removeAllItems];
    _decks = [DeckManager.sharedInstance retrieveDecks];
    if (_decks.count > 0) {
        for (NSManagedObject *deck in _decks) {
            [_importdeck.menu addItemWithTitle:[deck valueForKey:@"deckName"] action:nil keyEquivalent:@""];
        }
        [_importdeck selectItemAtIndex:0];
    }
    else {
        _useexistingdeckoption.enabled = false;
    }
}

- (void)loadColumnNames:(NSArray *)colarray {
    [_arraycontroller addObjects:colarray];
    [_tb reloadData];
    [self setMenus];
}

- (void)textDidChange:(NSNotification *)aNotification {
    if (_deckname.stringValue.length > 0 || _useexistingdeckoption.state == true) {
        _importbtn.enabled = YES;
    }
    else {
        _importbtn.enabled = NO;
    }
}

- (IBAction)import:(id)sender {
    _maparray = _arraycontroller.arrangedObjects;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    [self.window close];
}

- (IBAction)cancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}

- (IBAction)decktypechanged:(id)sender {
    [self decktypemenuchanged];
}

- (void)decktypemenuchanged {
    [self setMenus];
    NSMutableArray *array = [_arraycontroller mutableArrayValueForKey:@"content"];
    for (NSMutableDictionary *csvcol in array) {
        csvcol[@"destination"] = @"Do Not Map";
    }
    [_tb reloadData];
}

- (void)setMenus {
    switch (_decktype.selectedTag) {
        case DeckTypeKanji: {
            _kanamenuoption.hidden = YES;
            _primaryreadingmenuitem.hidden = NO;
            _primaryreadingtype.hidden = NO;
            _altreadingmenuitem.hidden = NO;
            _contextsentmenuitem1.hidden = YES;
            _contextsentmenuitem2.hidden = YES;
            _contextsentmenuitem3.hidden = YES;
            _engsentmenuitem1.hidden = YES;
            _engsentmenuitem2.hidden = YES;
            _engsentmenuitem3.hidden = YES;
            break;
        }
        case DeckTypeKana: {
            _kanamenuoption.hidden = YES;
            _primaryreadingmenuitem.hidden = YES;
            _primaryreadingtype.hidden = YES;
            _altreadingmenuitem.hidden = YES;
            _contextsentmenuitem1.hidden = NO;
            _contextsentmenuitem2.hidden = NO;
            _contextsentmenuitem3.hidden = YES;
            _engsentmenuitem1.hidden = NO;
            _engsentmenuitem2.hidden = NO;
            _engsentmenuitem3.hidden = YES;
            break;
        }
        case DeckTypeVocab: {
            _kanamenuoption.hidden = NO;
            _primaryreadingmenuitem.hidden = YES;
            _primaryreadingtype.hidden = YES;
            _altreadingmenuitem.hidden = YES;
            _contextsentmenuitem1.hidden = NO;
            _contextsentmenuitem2.hidden = NO;
            _contextsentmenuitem3.hidden = NO;
            _engsentmenuitem1.hidden = NO;
            _engsentmenuitem2.hidden = NO;
            _engsentmenuitem3.hidden = NO;
            break;
        }
    }
}
- (IBAction)toggle:(id)sender {
    if (_useexistingdeckoption.state == true) {
        _deckname.enabled = false;
        _decktype.enabled = false;
        _importdeck.enabled = true;
        [self setDeckPopup];
    }
    else {
        _deckname.enabled = true;
        _decktype.enabled = true;
        _importdeck.enabled = false;
    }
}

- (void)setDeckPopup {
    NSManagedObject *deck = _decks[_importdeck.indexOfSelectedItem];
    [_decktype selectItemAtIndex:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
    _decktype.enabled = false;
    [self decktypemenuchanged];
    _importbtn.enabled = true;
}

- (IBAction)deckchanged:(id)sender {
    [self setDeckPopup];
}

- (bool)checkDeckLimit:(bool)adding {
#if defined(AppStore)
    return true;
#else
    return [LicenseManager.sharedInstance checkDeckLimit:adding];
#endif
}
@end
