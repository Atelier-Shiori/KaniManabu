//
//  CSVImportController.h
//  KaniManabu
//
//  Created by 千代田桃 on 1/14/22.
//

#import <Cocoa/Cocoa.h>



@interface CSVImportController : NSWindowController
@property (strong) IBOutlet NSTableView *tb;
@property (strong) IBOutlet NSMenuItem *kanamenuoption;
@property (strong) IBOutlet NSMenuItem *primaryreadingmenuitem;
@property (strong) IBOutlet NSMenuItem *primaryreadingtype;
@property (strong) IBOutlet NSMenuItem *altreadingmenuitem;
@property (strong) IBOutlet NSMenuItem *contextsentmenuitem1;
@property (strong) IBOutlet NSMenuItem *contextsentmenuitem2;
@property (strong) IBOutlet NSMenuItem *contextsentmenuitem3;
@property (strong) IBOutlet NSMenuItem *engsentmenuitem1;
@property (strong) IBOutlet NSMenuItem *engsentmenuitem2;
@property (strong) IBOutlet NSMenuItem *engsentmenuitem3;
@property (strong) IBOutlet NSArrayController *arraycontroller;
@property (strong) IBOutlet NSTextField *deckname;
@property (strong) IBOutlet NSPopUpButton *decktype;
@property (strong) IBOutlet NSButton *importbtn;
@property (strong) NSArray *maparray;
@property (strong) IBOutlet NSPopUpButton *importdeck;
@property (strong) IBOutlet NSButton *useexistingdeckoption;
@property (strong) IBOutlet NSMenuItem *kunyomimenuitem;
@property (strong) NSArray *decks;
- (void)loadColumnNames:(NSArray *)colarray;
@end


