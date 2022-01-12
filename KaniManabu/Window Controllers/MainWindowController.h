//
//  MainWindowController.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import "DeckBrowser.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
@property (strong) IBOutlet NSTableView *tb;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) NSManagedObjectContext *moc;
@property (strong) DeckBrowser *deckbrowserwc;
@end

NS_ASSUME_NONNULL_END
