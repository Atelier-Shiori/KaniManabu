//
//  DeckBrowser.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import <PXSourceList/PXSourceList.h>



@interface DeckBrowser : NSWindowController <PXSourceListDataSource, PXSourceListDelegate, NSMenuDelegate, NSTableViewDelegate>
@property (strong) IBOutlet PXSourceList *sourceList;
@property (strong) IBOutlet NSViewController *sourceListViewController;
@property (strong) IBOutlet NSViewController *mainViewController;
@property (strong) NSUUID *currentDeckUUID;
@property int currentDeckType;
@property (strong) IBOutlet NSToolbarItem *addcardtoolbaritem;
@property (strong) IBOutlet NSArrayController *arraycontroller;
@property (strong) IBOutlet NSTableView *tb;
@end


