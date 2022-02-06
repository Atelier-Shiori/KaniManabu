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
#import "AppDelegate.h"

@interface DeckBrowser ()
@property (strong) NSSplitViewController *splitview;
@property (strong) NSMutableArray *sourceListItems;
@property (strong) IBOutlet NSSearchField *filterfield;
@property (strong) ItemInfoWindowController *iiwc;
@property (strong) IBOutlet NSMenuItem *contextEditCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextDeleteCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextViewCardMenuItem;
@property (strong) IBOutlet NSMenuItem *contextSuspendCardItem;
@property (strong) IBOutlet NSMenuItem *contextresetProgress;
@property bool refreshinprogress;
@property (strong) NSDate* nextAllowableiCloudUIRefreshDate;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong) IBOutlet NSToolbarItem *edittoolbaritem;
@property (strong) IBOutlet NSToolbarItem *deletetoolbaritem;
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
    if (@available(macOS 11.0, *)) {
        self.window.toolbarStyle = NSWindowToolbarStyleUnified;
    }
    else {
        _addcardtoolbaritem.image = [NSImage imageNamed:@"newdeck"];
        _edittoolbaritem.image = [NSImage imageNamed:@"edit"];
        _deletetoolbaritem.image = [NSImage imageNamed:@"delete"];
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckAdded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckRemoved" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"LearnEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    AppDelegate *delegate = (AppDelegate *)NSApp.delegate;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreRemoteChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"NSPersistentStoreRemoteChangeNotification" object:delegate.persistentContainer.persistentStoreCoordinator];
    [self.window.toolbar insertItemWithItemIdentifier:NSToolbarToggleSidebarItemIdentifier atIndex:0];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"DeckAdded"]||[notification.name isEqualToString:@"DeckRemoved"]||[notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification] || [notification.name isEqualToString:NSManagedObjectContextDidSaveNotification] ||[notification.name isEqualToString:@"LearnEnded"]||[notification.name isEqualToString:@"ReviewEnded"]||[notification.name isEqualToString:@"NSPersistentStoreRemoteChangeNotification"] || [notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification]) {
        if ([notification.name isEqualToString:@"NSPersistentStoreRemoteChangeNotification"] || [notification.name isEqualToString:NSPersistentStoreCoordinatorStoresDidChangeNotification] || [notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification]) {
            if (_nextAllowableiCloudUIRefreshDate) {
                if (_nextAllowableiCloudUIRefreshDate.timeIntervalSinceNow > 0) {
                    return;
                }
            }
            else {
                sleep(60);
            }
        }
        if (!DeckManager.sharedInstance.importing && !_refreshinprogress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Reload
                [self generateSourceList];
            });
        }
        if ([notification.name isEqualToString:@"NSPersistentStoreRemoteChangeNotification"] || [notification.name isEqualToString:NSPersistentStoreCoordinatorStoresDidChangeNotification]) {
            // Set next time CloudKit can refresh the UI
            _nextAllowableiCloudUIRefreshDate = [NSDate.date dateByAddingTimeInterval:300];
        }
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
    _refreshinprogress = true;
    NSPoint scrollOrigin = _sourceList.superview.bounds.origin;
    self.sourceListItems = [[NSMutableArray alloc] init];
    NSMutableArray *decks = [NSMutableArray new];
    PXSourceListItem *decksItem = [PXSourceListItem itemWithTitle:@"DECKS" identifier:@"decks"];
    for (NSManagedObject *deck in [[DeckManager sharedInstance] retrieveDecks]) {
        PXSourceListItem *sourceItem = [PXSourceListItem itemWithTitle:[deck valueForKey:@"deckName"] identifier:((NSUUID *)[deck valueForKey:@"deckUUID"]).UUIDString];
        if (@available(macOS 11.0, *)) {
            sourceItem.icon = [NSImage imageWithSystemSymbolName:@"menucard" accessibilityDescription:@""];
        } else {
            // Fallback on earlier versions
            sourceItem.icon = [NSImage imageNamed:@"deck"];
        }
        [decks addObject:sourceItem];
    }
    decksItem.children = decks;
    PXSourceListItem *stagesItem = [PXSourceListItem itemWithTitle:@"STAGES" identifier:@"stagegroup"];
    NSMutableArray *stageitems = [NSMutableArray new];
    bool oldmacOSVersion = false;
    if (@available(macOS 11.0, *)) {
        oldmacOSVersion = false;
    }
    else {
        oldmacOSVersion = true;
    }
    for (int i=0; i <5; i++) {
        NSString *stagename = @"";
        NSString *imagename = @"";
        switch (i) {
            case 0:
                stagename = @"Apprentice";
                imagename = !oldmacOSVersion ? @"oval.portrait" : @"egg";
                break;
            case 1:
                stagename = @"Guru";
                imagename = !oldmacOSVersion ? @"tortoise" : @"turtle";
                break;
            case 2:
                stagename = @"Master";
                imagename = !oldmacOSVersion ? @"hare" : @"rabbit";
                break;
            case 3:
                stagename =  @"Enlightened";
                imagename = !oldmacOSVersion ? @"star" : @"star";
                break;
            case 4:
                stagename = @"Burned";
                imagename = !oldmacOSVersion ? @"graduationcap" : @"gradhat";
                break;
            default:
                break;
        }
        PXSourceListItem *sourceItem = [PXSourceListItem itemWithTitle:stagename identifier:[NSString stringWithFormat:@"srsstage-%i",i]];
        if (@available(macOS 11.0, *)) {
            sourceItem.icon = [NSImage imageWithSystemSymbolName:imagename accessibilityDescription:@""];
        } else {
            // Fallback on earlier versions
            sourceItem.icon = [NSImage imageNamed:imagename];
        }
        [stageitems addObject:sourceItem];
    }
    stagesItem.children = stageitems;

    PXSourceListItem *otherItem = [PXSourceListItem itemWithTitle:@"OTHER" identifier:@"othergroup"];
    PXSourceListItem *allItem = [PXSourceListItem itemWithTitle:@"All Cards" identifier:@"allcards"];
    if (@available(macOS 12.0, *)) {
        allItem.icon = [NSImage imageWithSystemSymbolName:@"menucard" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        allItem.icon = [NSImage imageNamed:@"deck"];
    }
    PXSourceListItem *reviewItem = [PXSourceListItem itemWithTitle:@"Review Queue" identifier:@"reviewqueue"];
    if (@available(macOS 12.0, *)) {
        reviewItem.icon = [NSImage imageWithSystemSymbolName:@"menucard" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        reviewItem.icon = [NSImage imageNamed:@"deck"];
    }
    PXSourceListItem *criticalItem = [PXSourceListItem itemWithTitle:@"Critical Items" identifier:@"criticalitems"];
    if (@available(macOS 11.0, *)) {
        criticalItem.icon = [NSImage imageWithSystemSymbolName:@"exclamationmark.triangle" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        criticalItem.icon = [NSImage imageNamed:@"critical"];
    }
    otherItem.children = @[allItem, reviewItem, criticalItem];
    // Populate Source List
    [self.sourceListItems addObject:decksItem];
    [self.sourceListItems addObject:stagesItem];
    [self.sourceListItems addObject:otherItem];
    [_sourceList reloadData];
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"selecteddeck"]){
        NSNumber *selected = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"selecteddeck"];
        [_sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex: selected.unsignedIntegerValue]byExtendingSelection:false];
    }
    else{
         [_sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:1]byExtendingSelection:false];
    }
    [_sourceList.superview setBoundsOrigin:scrollOrigin];
    _refreshinprogress = false;
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
    _filterfield.stringValue = @"";
    [[NSUserDefaults standardUserDefaults] setValue:@(_sourceList.selectedRow) forKey:@"selecteddeck"];
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
    [alert addButtonWithTitle:NSLocalizedString(@"Delete",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    if (@available(macOS 11.0, *)) {
        [(NSButton *)alert.buttons[0] setHasDestructiveAction:YES];
    }
    [(NSButton *)alert.buttons[0] setKeyEquivalent: @""];
    [(NSButton *)alert.buttons[1] setKeyEquivalent: @"\033"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            if ([DeckManager.sharedInstance deleteCardWithCardUUID:[card valueForKey:@"carduuid"] withType:((NSNumber *)[card valueForKey:@"cardtype"]).intValue]) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"CardRemoved" object:[card valueForKey:@"carduuid"]];
                [self loadDeck];
            }
        }
    }];
}

- (void)loadDeck {
    // Save Scroll orgin
    NSPoint scrollOrigin = _tb.superview.bounds.origin;
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
    else if ([identifier isEqualToString:@"allcards"]) {
        _currentDeckUUID = nil;
        _currentDeckType = -1;
        _addcardtoolbaritem.enabled = false;
        [self loadallitems];
    }
    else if ([identifier isEqualToString:@"reviewqueue"]) {
        _currentDeckUUID = nil;
        _currentDeckType = -1;
        _addcardtoolbaritem.enabled = false;
        [self loadreviewitems];
    }
    else {
        _addcardtoolbaritem.enabled = true;
        _currentDeckUUID = [[NSUUID alloc] initWithUUIDString:identifier];
        NSManagedObject *deckMetadata = [DeckManager.sharedInstance getDeckMetadataWithUUID:_currentDeckUUID];
        _currentDeckType = ((NSNumber *)[deckMetadata valueForKey:@"deckType"]).intValue;
        NSArray *cards = [DeckManager.sharedInstance retrieveCardsForDeckUUID:_currentDeckUUID withType:_currentDeckType];
        [self populateTableViewWithArray:cards];
    }
    [self filteritems];
    [_tb.superview setBoundsOrigin:scrollOrigin];
}

- (void)populateTableViewWithArray:(NSArray *)array {
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSMutableArray *a = [self.arraycontroller mutableArrayValueForKey:@"content"];
        //[a removeAllObjects];
        [self.arraycontroller setContent:nil];
        [self.arraycontroller addObjects:array];
        [self.tb reloadData];
        [self.tb deselectAll:self];
        if (@available(macOS 11.0, *)) {
            self.window.subtitle = array.count == 1 ? @"1 item" : [NSString stringWithFormat:@"%lu items",(unsigned long)array.count];
        } else {
            // Fallback on earlier versions
            self.window.title = [NSString stringWithFormat:@"Deck Browser (%@)", array.count == 1 ? @"1 item" : [NSString stringWithFormat:@"%lu items",(unsigned long)array.count]];
        }
    });
}

- (void)loadSRSStageCards:(int)stage {
    [DeckManager.sharedInstance.moc performBlock:^{
        NSPredicate *predicate;
        switch (stage) {
            case 0:
                predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i AND learned == %@" , 4, @YES];
                break;
            case 1:
                predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i && srsstage >= %i AND learned == %@" , 6, 5, @YES];
                break;
            case 2:
                predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 7, @YES];
                break;
            case 3:
                predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 8, @YES];
                break;
            case 4:
                predicate = [NSPredicate predicateWithFormat:@"srsstage == %i AND learned == %@" , 9, @YES];
                break;
            default:
                break;
        }
        NSMutableArray *tmparray = [NSMutableArray new];
        for (int i = 0; i < 3; i++) {
            [tmparray addObjectsFromArray:[DeckManager.sharedInstance retrieveAllCardswithType:i withPredicate:predicate]];
        }
        [self populateTableViewWithArray:tmparray];
    }];
}

- (void)loadcriticalitems {
    [DeckManager.sharedInstance.moc performBlock:^{
        NSMutableArray *tmparray = [NSMutableArray new];
        for (int i = 0; i < 3; i++) {
            [tmparray addObjectsFromArray:[DeckManager.sharedInstance retrieveAllCriticalCardswithType:i]];
        }
        [self populateTableViewWithArray:tmparray];
    }];
}

- (void)loadreviewitems {
    [DeckManager.sharedInstance.moc performBlock:^{
        NSMutableArray *tmparray = [NSMutableArray new];
        NSArray *decks = [DeckManager.sharedInstance retrieveDecks];
        for (NSManagedObject *deck in decks) {
            if (!((NSNumber *)[deck valueForKey:@"enabled"]).boolValue) {
                continue;
            }
            NSArray *cards = [DeckManager.sharedInstance retrieveReviewItemsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
            for (NSManagedObject *obj in cards) {
                NSArray *keys = obj.entity.attributesByName.allKeys;
                NSMutableDictionary *tmpdict = [NSMutableDictionary dictionaryWithDictionary:[obj dictionaryWithValuesForKeys:keys]];
                tmpdict[@"managedObject"] = obj;
                tmpdict[@"cardtype"] = [deck valueForKey:@"deckType"];
                [tmparray addObject:tmpdict];
            }
        }
        [self populateTableViewWithArray:tmparray];
    }];
}

- (void)loadallitems {
    [DeckManager.sharedInstance.moc performBlock:^{
        NSMutableArray *tmparray = [NSMutableArray new];
        for (int i = 0; i < 3; i++) {
            [tmparray addObjectsFromArray:[DeckManager.sharedInstance retrieveAllCardswithType:i withPredicate:nil]];
        }
        [self populateTableViewWithArray:tmparray];
    }];
}


- (IBAction)tbdoubleaction:(id)sender {
    [self performViewCard];
}

- (void)performViewCard {
    if (_arraycontroller.selectedObjects.count > 0) {
        NSDictionary *selected = [_arraycontroller selectedObjects][0];
        if (!_iiwc) {
            _iiwc = [ItemInfoWindowController new];
        }
        [_iiwc.window makeKeyAndOrderFront:self];
        [_iiwc setDictionary:selected withWindowType:ParentWindowTypeDeckBrowser];
    }
}

- (void)performResetProgress {
    NSDictionary *card =  [_arraycontroller selectedObjects][0];
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Reset Card's Progress?";
    alert.informativeText = [NSString stringWithFormat:@"Do you want to reset the review progress for card, %@ and put it back in the learning queue? This cannot be undone", [card valueForKey:@"japanese"]];
    [alert addButtonWithTitle:NSLocalizedString(@"Reset",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    if (@available(macOS 11.0, *)) {
        [(NSButton *)alert.buttons[0] setHasDestructiveAction:YES];
    }
    [(NSButton *)alert.buttons[0] setKeyEquivalent: @""];
    [(NSButton *)alert.buttons[1] setKeyEquivalent: @"\033"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [DeckManager.sharedInstance resetCardWithCardUUID:[card valueForKey:@"carduuid"] withType:((NSNumber *)[card valueForKey:@"cardtype"]).intValue];
        }
    }];
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
    if (validclick) {
        _contextresetProgress.enabled = ((NSNumber *)[_arraycontroller selectedObjects][0][@"learned"]).boolValue;
    }
    else {
        _contextresetProgress.enabled = false;
    }
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
- (IBAction)resetcontext:(id)sender {
    [self performResetProgress];
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
- (IBAction)filteraction:(id)sender {
    [self filteritems];
}

- (void)filteritems {
    if (_filterfield.stringValue.length > 0) {
        NSString *str = _filterfield.stringValue;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"japanese CONTAINS[cd] %@ OR english CONTAINS[cd] %@ OR altmeaning CONTAINS[cd] %@ OR kanaWord CONTAINS[cd] %@ OR altreading CONTAINS[cd] %@ OR reading CONTAINS[cd] %@ OR tags CONTAINS[cd] %@", str,str,str,str,str,str,str];
        _arraycontroller.filterPredicate = predicate;
        [_tb reloadData];
    }
    else {
        _arraycontroller.filterPredicate = nil;
        [_tb reloadData];
    }
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
    if ([tableColumn.identifier isEqualToString:@"nextreview"]) {
        double date = ((NSNumber *)_arraycontroller.arrangedObjects[row][@"nextreviewinterval"]).doubleValue;
        if (date == 0) {
            tcell.stringValue = @"";
        }
    }
}
@end
