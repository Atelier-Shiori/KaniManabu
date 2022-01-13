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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckAdded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckRemoved" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"LearnEnded" object:nil];
    
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"DeckAdded"]||[notification.name isEqualToString:@"DeckRemoved"]||[notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification]) {
        // Reload
        [self generateSourceList];
    }
}

- (void)windowWillClose:(NSNotification *)notification{
    [NSNotificationCenter.defaultCenter postNotificationName:@"CardBrowserClosed" object:nil];
}

- (void)setUpSplitView {
    _splitview = [NSSplitViewController new];
    NSSplitViewItem *sourceListSplitViewItem = [NSSplitViewItem sidebarWithViewController:_sourceListViewController];
    NSSplitViewItem *mainViewSplitViewItem = [NSSplitViewItem splitViewItemWithViewController:_mainViewController];
    sourceListSplitViewItem.maximumThickness = 250;
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
    PXSourceListItem *stagesItem = [PXSourceListItem itemWithTitle:@"STAGES" identifier:@"searchgroup"];
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

    // Populate Source List
    [self.sourceListItems addObject:decksItem];
    [self.sourceListItems addObject:stagesItem];
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
    NSUUID *selecteduuid = [_arraycontroller selectedObjects][0][@"carduuid"];
    switch (_currentDeckType) {
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
    self.window.subtitle = array.count == 1 ? @"1 item" : [NSString stringWithFormat:@"%i items",array.count];
}

- (void)loadSRSStageCards:(int)stage {
    NSPredicate *predicate;
    switch (stage) {
        case 0:
            predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i" , 3];
            break;
        case 1:
            predicate = [NSPredicate predicateWithFormat:@"srsstage <= %i && srsstage >= %i" , 5, 4];
            break;
        case 2:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i" , 6];
            break;
        case 3:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i" , 7];
            break;
        case 4:
            predicate = [NSPredicate predicateWithFormat:@"srsstage == %i" , 8];
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
- (IBAction)tbdoubleaction:(id)sender {
    NSDictionary *selected = [_arraycontroller selectedObjects][0];
    if (!_iiwc) {
        _iiwc = [ItemInfoWindowController new];
    }
    [_iiwc.window makeKeyAndOrderFront:self];
    [_iiwc setDictionary:selected withWindowType:ParentWindowTypeDeckBrowser];
}

@end
