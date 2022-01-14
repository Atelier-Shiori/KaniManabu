//
//  DeckBrowser.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import "DeckBrowser.h"
#import "SRScheduler.h"
#import "DeckManager.h"
#import "CardEditor.h"
#import "ItemInfoWindowController.h"

@interface DeckBrowser ()
@property (strong) NSSplitViewController *splitview;
@property (strong) NSMutableArray *sourceListItems;
@property (strong) ItemInfoWindowController *iiwc;
@property (strong) IBOutlet NSMenuItem *contextEditCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextDeleteCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextViewCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextSuspendCardItem;
@end

@implementation DeckBrowser
- (instancetype)init {
    self = [super initWithWindowNibName:@"DeckBrowser"];
    if (!self)
        return nil;
    return self;
}

- (void)awakeFromNib {
    // Setup Splitview
    [self setUpSplitView];
    [self generateSourceList];
    self.window.toolbarStyle = NSWindowToolbarStyleUnified;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"selecteddeck"]){
        NSNumber *selected = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"selecteddeck"];
        [_sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex: selected.unsignedIntegerValue]byExtendingSelection:false];
    }
    else{
         [_sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:1]byExtendingSelection:false];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckAdded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckRemoved" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"LearnEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreRemoteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:nil];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"DeckAdded"]||[notification.name isEqualToString:@"DeckRemoved"]||[notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification] || [notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification] || [notification.name isEqualToString:NSPersistentStoreCoordinatorStoresWillChangeNotification] || [notification.name isEqualToString:NSPersistentStoreCoordinatorStoresDidChangeNotification]||[notification.name isEqualToString:@"LearnEnded"]||[notification.name isEqualToString:@"ReviewEnded"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Reload
            [self generateSourceList];
        });
    }
}

- (void)windowWillClose:(NSNotification *)notification{
    [NSNotificationCenter.defaultCenter postNotificationName:@"CardBrowserClosed" object:nil];
}

- (void)setUpSplitView {
    _splitview = [NSSplitViewController new];
    NSSplitViewItem *sourceListSplitViewItem = [NSSplitViewItem sidebarWithViewController:_sourceListViewController];
    NSSplitViewItem *mainViewSplitViewItem = [NSSplitViewItem splitViewItemWithViewController:_mainViewController];
    sourceListSplitViewItem.maximumThickness = 280;
    [_splitview addSplitViewItem:sourceListSplitViewItem];
    [_splitview addSplitViewItem:mainViewSplitViewItem];
    _splitview.splitView.autosaveName = @"mainWindowSplitView";
    [self.window setContentViewController:_splitview];
}

- (void)generateSourceList {
    self.sourceListItems = [[NSMutableArray alloc] init];
    NSMutableArray *decks = [NSMutableArray new];
    PXSourceListItem *decksItem = [PXSourceListItem itemWithTitle:@"DECKS" identifier:@"decks"];
    for (NSManagedObject *deck in [[DeckManager sharedInstance] retrieveDecks]) {
        PXSourceListItem *sourceItem = [PXSourceListItem itemWithTitle:[deck valueForKey:@"deckName"] identifier:((NSUUID *)[deck valueForKey:@"deckUUID"]).UUIDString];
        sourceItem.icon = [NSImage imageWithSystemSymbolName:@"menucard" accessibilityDescription:@""];
        [decks addObject:sourceItem];
    }
    decksItem.children = decks;
    PXSourceListItem *stagesItem = [PXSourceListItem itemWithTitle:@"STAGES" identifier:@"stagegroup"];
    NSMutableArray *stageitems = [NSMutableArray new];
    for (int i=0; i <5; i++) {
        NSString *stagename = @"";
        NSString *imagename = @"";
        switch (i) {
            case 0:
                stagename = @"Apprentice";
                imagename = @"oval.portrait";
                break;
            case 1:
                stagename = @"Guru";
                imagename = @"tortoise";
                break;
            case 2:
                stagename = @"Master";
                imagename = @"hare";
                break;
            case 3:
                stagename =  @"Enlightened";
                imagename = @"star";
                break;
            case 4:
                stagename = @"Burned";
                imagename = @"graduationcap";
                break;
            default:
                break;
        }
        PXSourceListItem *sourceItem = [PXSourceListItem itemWithTitle:stagename identifier:[NSString stringWithFormat:@"srsstage-%i",i]];
        sourceItem.icon = [NSImage imageWithSystemSymbolName:imagename accessibilityDescription:@""];
        [stageitems addObject:sourceItem];
    }
    stagesItem.children = stageitems;

    PXSourceListItem *otherItem = [PXSourceListItem itemWithTitle:@"OTHER" identifier:@"othergroup"];
    PXSourceListItem *criticalItem = [PXSourceListItem itemWithTitle:@"Critical Items" identifier:@"criticalitems"];
    criticalItem.icon = [NSImage imageWithSystemSymbolName:@"exclamationmark.triangle" accessibilityDescription:@""];
    otherItem.children = @[criticalItem];
    // Populate Source List
    [self.sourceListItems addObject:decksItem];
    [self.sourceListItems addObject:stagesItem];
    [self.sourceListItems addObject:otherItem];
    [_sourceList reloadData];

}


#pragma mark -
#pragma mark Source List Data Source Methods
- (NSUInteger)sourceList:(PXSourceList*)sourceList numberOfChildrenOfItem:(id)item
{
    if (!item)
        return self.sourceListItems.count;
    
    return [item children].count;
}

- (id)sourceList:(PXSourceList*)aSourceList child:(NSUInteger)index ofItem:(id)item
{
    if (!item)
        return self.sourceListItems[index];
    
    return [item children][index];
}

- (BOOL)sourceList:(PXSourceList*)aSourceList isItemExpandable:(id)item
{
    return [item hasChildren];
}

#pragma mark Source List Delegate Methods
- (NSView *)sourceList:(PXSourceList *)aSourceList viewForItem:(id)item
{
    PXSourceListTableCellView *cellView = nil;
    if ([aSourceList levelForItem:item] == 0)
        cellView = [aSourceList makeViewWithIdentifier:@"HeaderCell" owner:nil];
    else
        cellView = [aSourceList makeViewWithIdentifier:@"MainCell" owner:nil];
    
    PXSourceListItem *sourceListItem = item;
    
    // Only allow us to edit the user created photo collection titles.
    cellView.textField.editable = false;
    cellView.textField.selectable = false;
    
    cellView.textField.stringValue = sourceListItem.title ? sourceListItem.title : [sourceListItem.representedObject title];
    cellView.imageView.image = [item icon];
    
    return cellView;
}


- (BOOL)sourceList:(PXSourceList*)aSourceList isGroupAlwaysExpanded:(id)group
{
    if([[group identifier] isEqualToString:@"decks"])
        return YES;
    else if([[group identifier] isEqualToString:@"stages"])
        return YES;
    return YES;
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setValue:@(_sourceList.selectedRow) forKey:@"selectedmainview"];
    [self loadDeck];
}

#pragma mark Card Management

- (IBAction)newCard:(id)sender {
    switch (_currentDeckType) {
        case DeckTypeVocab: {
            [CardEditor openVocabCardEditorWithUUID:_currentDeckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
                    [self loadDeck];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"CardAdded" object:nil];
                }
            }];
            break;
        }
        case DeckTypeKana: {
            [CardEditor openKanaCardEditorWithUUID:_currentDeckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
                    [self loadDeck];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"CardAdded" object:nil];
                }
            }];
            break;
        }
        case DeckTypeKanji: {
            [CardEditor openKanjiCardEditorWithUUID:_currentDeckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
                    [self loadDeck];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"CardAdded" object:nil];
                }
            }];
            break;
        }
        default: {
            break;
        }
    }
}

- (IBAction)editCard:(id)sender {
    [self performEditCard];
}

- (void)performEditCard {
    NSUUID *selecteduuid = [_arraycontroller selectedObjects][0][@"carduuid"];
    int type = _currentDeckType == -1 ? ((NSNumber *)[_arraycontroller selectedObjects][0][@"cardtype"]).intValue : _currentDeckType;
    switch (type) {
            case DeckTypeVocab: {
                [CardEditor openVocabCardEditorWithUUID:selecteduuid isNewCard:false withWindow:self.window completionHandler:^(bool success) {
                    if (success) {
                        [self loadDeck];
                        [NSNotificationCenter.defaultCenter postNotificationName:@"CardModified" object:selecteduuid];
                    }
                }];
                break;
            }
            case DeckTypeKana: {
                [CardEditor openKanaCardEditorWithUUID:selecteduuid isNewCard:false withWindow:self.window completionHandler:^(bool success) {
                    if (success) {
                        [self loadDeck];
                        [NSNotificationCenter.defaultCenter postNotificationName:@"CardModified" object:selecteduuid];
                    }
                }];
                break;
            }
            case DeckTypeKanji: {
                [CardEditor openKanjiCardEditorWithUUID:selecteduuid isNewCard:false withWindow:self.window completionHandler:^(bool success) {
                    if (success) {
                        [self loadDeck];
                        [NSNotificationCenter.defaultCenter postNotificationName:@"CardModified" object:selecteduuid];
                    }
                }];
                break;
            }
            default: {
                break;
            }
    }
}

- (IBAction)deleteCard:(id)sender {
    [self performdeleteCard];
}

- (void)performdeleteCard {
    NSDictionary *card =  [_arraycontroller selectedObjects][0];
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Delete card?";
    alert.informativeText = [NSString stringWithFormat:@"Do you want to delete card, %@? This cannot be undone", [card valueForKey:@"japanese"]];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            if ([DeckManager.sharedInstance deleteCardWithCardUUID:[card valueForKey:@"carduuid"] withType:((NSNumber *)[card valueForKey:@"cardtype"]).intValue]) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"CardRemoved" object:[card valueForKey:@"carduuid"]];
                [self loadDeck];
            }
        }
    }];
}

- (void)loadDeck {
    NSIndexSet *selectedIndexes = _sourceList.selectedRowIndexes;
    NSString *identifier = [[_sourceList itemAtRow:selectedIndexes.firstIndex] identifier];
    if ([identifier containsString:@"srsstage-"]) {
        _currentDeckUUID = nil;
        _currentDeckType = -1;
        _addcardtoolbaritem.enabled = false;
        [self loadSRSStageCards:[identifier stringByReplacingOccurrencesOfString:@"srsstage-" withString:@""].intValue];
    }
    else if ([identifier isEqualToString:@"criticalitems"]) {
        _currentDeckUUID = nil;
        _currentDeckType = -1;
        _addcardtoolbaritem.enabled = false;
        [self loadcriticalitems];
    }
    else {
        _addcardtoolbaritem.enabled = true;
        _currentDeckUUID = [[NSUUID alloc] initWithUUIDString:identifier];
        NSManagedObject *deckMetadata = [DeckManager.sharedInstance getDeckMetadataWithUUID:_currentDeckUUID];
        _currentDeckType = ((NSNumber *)[deckMetadata valueForKey:@"deckType"]).intValue;
        NSArray *cards = [DeckManager.sharedInstance retrieveCardsForDeckUUID:_currentDeckUUID withType:_currentDeckType];
        [self populateTableViewWithArray:cards];
    }
}

- (void)populateTableViewWithArray:(NSArray *)array {
    NSMutableArray *a = [_arraycontroller mutableArrayValueForKey:@"content"];
    [a removeAllObjects];
    [_arraycontroller addObjects:array];
    [_tb reloadData];
    [_tb deselectAll:self];
    self.window.subtitle = array.count == 1 ? @"1 item" : [NSString stringWithFormat:@"%lu items",(unsigned long)array.count];
}

- (void)loadSRSStageCards:(int)stage {
    NSPredicate *predicate;
    switch (stage) {
        case 0:
            predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i AND learned == %@" , 3, @YES];
            break;
        case 1:
            predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i && srsstage >= %i AND learned == %@" , 5, 4, @YES];
            break;
        case 2:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 6, @YES];
            break;
        case 3:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 7, @YES];
            break;
        case 4:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 8, @YES];
            break;
        default:
            break;
    }
    NSMutableArray *tmparray = [NSMutableArray new];
    for (int i = 0; i < 3; i++) {
        [tmparray addObjectsFromArray:[DeckManager.sharedInstance retrieveAllCardswithType:i withPredicate:predicate]];
    }
    [self populateTableViewWithArray:tmparray];
}

- (void)loadcriticalitems {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (int i = 0; i < 3; i++) {
        [tmparray addObjectsFromArray:[DeckManager.sharedInstance retrieveAllCriticalCardswithType:i]];
    }
    [self populateTableViewWithArray:tmparray];
}

- (IBAction)tbdoubleaction:(id)sender {
    [self performViewCard];
}

- (void)performViewCard {
    NSDictionary *selected = [_arraycontroller selectedObjects][0];
    if (!_iiwc) {
        _iiwc = [ItemInfoWindowController new];
    }
    [_iiwc.window makeKeyAndOrderFront:self];
    [_iiwc setDictionary:selected withWindowType:ParentWindowTypeDeckBrowser];
}

#pragma mark Context menu
- (void)menuWillOpen:(NSMenu *)menu {
    [self setPopupMenuState];
}

- (void)setPopupMenuState {
    long rightClickSelectedRow = self.tb.clickedRow;
    [self.tb selectRowIndexes:[[NSIndexSet alloc] initWithIndex:rightClickSelectedRow] byExtendingSelection:NO];
    bool validclick = rightClickSelectedRow >= 0;
    _contextEditCardMenuItem.enabled = validclick;
    _contextDeleteCardMenuItem.enabled = validclick;
    _contextSuspendCardItem.enabled = validclick;
    _contextViewCardMenuItem.enabled = validclick;
}
- (IBAction)editcontext:(id)sender {
    long rightClickSelectedRow = self.tb.clickedRow;
    [self.tb selectRowIndexes:[[NSIndexSet alloc] initWithIndex:rightClickSelectedRow] byExtendingSelection:NO];
    [self performEditCard];
}
- (IBAction)deletecontext:(id)sender {
    long rightClickSelectedRow = self.tb.clickedRow;
    [self.tb selectRowIndexes:[[NSIndexSet alloc] initWithIndex:rightClickSelectedRow] byExtendingSelection:NO];
    [self performdeleteCard];
}
- (IBAction)viewcontext:(id)sender {
    long rightClickSelectedRow = self.tb.clickedRow;
    [self.tb selectRowIndexes:[[NSIndexSet alloc] initWithIndex:rightClickSelectedRow] byExtendingSelection:NO];
    [self performViewCard];
}
- (IBAction)suspendcontext:(id)sender {
    long rightClickSelectedRow = self.tb.clickedRow;
    [self.tb selectRowIndexes:[[NSIndexSet alloc] initWithIndex:rightClickSelectedRow] byExtendingSelection:NO];
    NSDictionary *card =  [_arraycontroller selectedObjects][0];
    [DeckManager.sharedInstance togglesuspendCardForCardUUID:[card valueForKey:@"carduuid"] withType:((NSNumber *)[card valueForKey:@"cardtype"]).intValue];
    [self loadDeck];
}

#pragma mark NSTableViewDelegate
- (void)tableView:(NSTableView *)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {
    bool suspended = ((NSNumber *)_arraycontroller.arrangedObjects[row][@"suspended"]).boolValue;
    NSTextFieldCell *tcell = (NSTextFieldCell *)cell;
    NSMutableAttributedString *astr = [[NSMutableAttributedString alloc] initWithString:tcell.stringValue];
    if (suspended) {
        [astr addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [astr length])];
    }
    [tcell setAttributedStringValue:astr];
}
@end
