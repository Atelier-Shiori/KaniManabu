//
//  MainWindowController.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "DeckManager.h"
#import "DeckAddDialogController.h"
#import "DeckViewCell.h"
#import "CardEditor.h"
#import "LearnWindowController.h"
#import "ReviewWindowController.h"
#import "CardReview.h"
#import "MSWeakTimer.h"
#import "CSVImportController.h"
#import "CSVDeckImporter.h"

@interface MainWindowController ()
@property (strong)LearnWindowController *lwc;
@property (strong)ReviewWindowController *rwc;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong, nonatomic) MSWeakTimer *refreshtimer;
@property long totallearnitemcount;
@property long totalreviewitemcount;
@property (strong) CSVImportController *csvic;
@end

@implementation MainWindowController
- (instancetype)init {
    self = [super initWithWindowNibName:@"mainwindow"];
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
    [_tb registerNib:[[NSNib alloc]initWithNibNamed:@"DeckViewCell" bundle:nil] forIdentifier:@"deckviewcell"];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"CardBrowserClosed" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"LearnEnded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckAdded" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"DeckRemoved" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"StartLearning" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"StartReviewing" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ActionDeleteDeck" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ActionAddCard" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreRemoteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"StartLearningReviewQuiz" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"AddToQueueCount" object:nil];
    AppDelegate *delegate = (AppDelegate *)NSApp.delegate;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreRemoteChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
    [self loadDeckArrayAndPopulate];
    //Review Queue timer
    _privateQueue = dispatch_queue_create("moe.ateliershiori.Shukofukurou", DISPATCH_QUEUE_CONCURRENT);
    _refreshtimer =  [MSWeakTimer scheduledTimerWithTimeInterval:900
                                                          target:self
                                                        selector:@selector(fireTimer)
                                                        userInfo:nil
                                                         repeats:YES
                                                   dispatchQueue:_privateQueue];
}

- (void)fireTimer {
    _totalreviewitemcount = 0;
    _totallearnitemcount = 0;
    [NSNotificationCenter.defaultCenter postNotificationName:@"TimerFired" object:nil];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"CardBrowserClosed"] || [notification.name isEqualToString:@"LearnEnded"] || [notification.name isEqualToString:@"ReviewEnded"]) {
        [self.window makeKeyAndOrderFront:self];
        if( [notification.name isEqualToString:@"ReviewEnded"]) {
            _totalreviewitemcount = 0;
            _totallearnitemcount = 0;
            [_moc save:nil];
        }
    }
    else if ([notification.name isEqualToString:@"DeckAdded"] || [notification.name isEqualToString:@"DeckRemoved"]) {
        // Reload
        dispatch_async(dispatch_get_main_queue(), ^{
            self.totalreviewitemcount = 0;
            self.totallearnitemcount = 0;
            [self loadDeckArrayAndPopulate];
        });
    }
    else if ([notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification] || [notification.name isEqualToString:NSPersistentStoreCoordinatorStoresDidChangeNotification]) {
        // Reload
        sleep(5);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.totalreviewitemcount = 0;
            self.totallearnitemcount = 0;
            [self loadDeckArrayAndPopulate];
        });
    }
    else if ([notification.name isEqualToString:@"ActionAddCard"]) {
        if ([notification.object isKindOfClass:[NSManagedObject class]]) {
            NSManagedObject *deck = notification.object;
            [self performAddCard:[deck valueForKey:@"deckUUID"] withDeckType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
        }
    }
    else if ([notification.name isEqualToString:@"ActionDeleteDeck"]) {
        if ([notification.object isKindOfClass:[NSManagedObject class]]) {
            NSManagedObject *deck = notification.object;
            [self deletedeckWithDeck:deck];
        }
    }
    else if ([notification.name isEqualToString:@"StartLearning"]) {
        if ([notification.object isKindOfClass:[NSManagedObject class]]) {
            NSManagedObject *deck = notification.object;
            [self performStartLearnWithDeck:deck];
        }
        else {
            NSAlert *alert = [[NSAlert alloc] init] ;
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"No cards in learning queue."];
            alert.informativeText = @"This deck has no cards in the learning queue.";
            alert.alertStyle = NSAlertStyleInformational;
            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                }];
        }
    }
    else if ([notification.name isEqualToString:@"StartReviewing"]) {
        if ([notification.object isKindOfClass:[NSManagedObject class]]) {
            NSManagedObject *deck = notification.object;
            [self performStartReviewWithDeck:deck];
        }
        else {
            NSAlert *alert = [[NSAlert alloc] init] ;
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"No cards in review queue."];
            alert.informativeText = @"This deck has no cards in the review queue. Check back later.";
            alert.alertStyle = NSAlertStyleInformational;
            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                }];
        }
    }
    else if ([notification.name isEqualToString:@"StartLearningReviewQuiz"]) {
        [self performStartLearnQuiz];
    }
    else if ([notification.name isEqualToString:@"AddToQueueCount"]) {
        if ([notification.object isKindOfClass:[NSDictionary class]]) {
            long totalreviewcount = ((NSNumber *)notification.object[@"reviewcount"]).longValue;
            long totallearncount = ((NSNumber *)notification.object[@"learncount"]).longValue;
            _totalreviewitemcount = _totalreviewitemcount + totalreviewcount;
            _totallearnitemcount = _totallearnitemcount + totallearncount;
            long totalqueue = _totallearnitemcount+_totalreviewitemcount;
            bool nonzerototalqueuecount = (_totallearnitemcount+_totalreviewitemcount) > 0;
            NSApp.dockTile.showsApplicationBadge = nonzerototalqueuecount;
            NSApp.dockTile.badgeLabel = nonzerototalqueuecount ? @(totalqueue).stringValue : @"";
            [NSApp.dockTile display];
        }
    }
}

- (void)performAddCard:(NSUUID *)deckUUID withDeckType:(int)type {
    switch (type) {
        case DeckTypeVocab: {
            [CardEditor openVocabCardEditorWithUUID:deckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
                    [NSNotificationCenter.defaultCenter postNotificationName:@"CardAdded" object:nil];
                }
            }];
            break;
        }
        case DeckTypeKana: {
            [CardEditor openKanaCardEditorWithUUID:deckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
                    [NSNotificationCenter.defaultCenter postNotificationName:@"CardAdded" object:nil];
                }
            }];
            break;
        }
        case DeckTypeKanji: {
            [CardEditor openKanjiCardEditorWithUUID:deckUUID isNewCard:true withWindow:self.window completionHandler:^(bool success) {
                if (success) {
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

- (void)performStartLearnWithDeck:(NSManagedObject *)deck {
    _lwc = [LearnWindowController new];
    [_lwc.window makeKeyAndOrderFront:self];
    [_lwc loadStudyItemsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
    [self.window orderOut:self];
}

- (void)performStartLearnQuiz {
    _rwc = [ReviewWindowController new];
    _rwc.learnmode = YES;
    [_rwc.window makeKeyAndOrderFront:self];
    [_rwc startReview:_lwc.studyitems];
    [self.window orderOut:self];
}

- (void)performStartReviewWithDeck:(NSManagedObject *)deck {
    _rwc = [ReviewWindowController new];
    [_rwc.window makeKeyAndOrderFront:self];
    int deckType = ((NSNumber *)[deck valueForKey:@"deckType"]).intValue;
    NSArray *reviewitems = [DeckManager.sharedInstance retrieveReviewItemsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:deckType];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSManagedObject *card in reviewitems) {
        CardReview *creview = [[CardReview alloc] initWithCard:card withCardType:deckType];
        creview.cardtype = deckType;
        creview.card = card;
        [tmparray addObject:creview];
    }
    [_rwc startReview:tmparray];
    [self.window orderOut:self];
}

- (void)loadDeckArrayAndPopulate {
    NSMutableArray *a = [_arrayController mutableArrayValueForKey:@"content"];
    [a removeAllObjects];
    [_arrayController addObjects:[DeckManager.sharedInstance retrieveDecks]];
    [_tb reloadData];
    [_tb deselectAll:self];
}
- (void)windowWillClose:(NSNotification *)notification{
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)openDeckBrowser:(id)sender {
    if (((NSMutableArray *)_arrayController.content).count == 0) {
        // No Cards, show error
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"You have no decks"];
        alert.informativeText = @"Create or import a deck first before using this feature.";
        alert.alertStyle = NSAlertStyleInformational;
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            }];
        return;
    }
    if (!_deckbrowserwc) {
        _deckbrowserwc = [DeckBrowser new];
    }
    [_deckbrowserwc.window makeKeyAndOrderFront:self];
    [self.window orderOut:self];
}
- (IBAction)addNewDeck:(id)sender {
    DeckAddDialogController *dadddialog = [DeckAddDialogController new];
    [self.window beginSheet:dadddialog.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseOK) {
                // Check if deck exists
                if ([DeckManager.sharedInstance checkDeckExists:dadddialog.deckname.stringValue withType:dadddialog.typebtn.selectedTag]) {
                    NSAlert *alert = [[NSAlert alloc] init] ;
                    [alert addButtonWithTitle:@"OK"];
                    [alert setMessageText:@"Deck already exists"];
                    alert.informativeText = [NSString stringWithFormat:@"Deck %@ already exists. You cannot create a deck with the same deck name and type.", dadddialog.deckname.stringValue];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                        }];
                }
                else {
                    bool success = [DeckManager.sharedInstance createDeck:dadddialog.deckname.stringValue withType:dadddialog.typebtn.selectedTag];
                    if (!success) {
                        NSAlert *alert = [[NSAlert alloc] init] ;
                        [alert addButtonWithTitle:@"OK"];
                        [alert setMessageText:@"Couldn't create deck."];
                        alert.informativeText = [NSString stringWithFormat:@"%@ failed to create.", dadddialog.deckname.stringValue];
                        alert.alertStyle = NSAlertStyleInformational;
                        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                            }];
                    }
                    else {
                        [NSNotificationCenter.defaultCenter postNotificationName:@"DeckAdded" object:nil];
                    }
                }
            }
        }];
}

- (void)deletedeckWithDeck:(NSManagedObject *)selectedDeck {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Delete Deck?";
    alert.informativeText = [NSString stringWithFormat:@"Do you want to delete deck, %@? This cannot be undone", [selectedDeck valueForKey:@"deckName"]];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            NSUUID *deckuuid = [selectedDeck valueForKey:@"deckUUID"];
            int decktype = ((NSNumber *)[selectedDeck valueForKey:@"deckType"]).intValue;
            if ([DeckManager.sharedInstance deleteDeckWithDeckUUID:deckuuid]) {
                // Remove cards from associated deck and notify.
                [DeckManager.sharedInstance deleteAllCardsForDeckUUID:deckuuid withType:decktype];
                [NSNotificationCenter.defaultCenter postNotificationName:@"DeckRemoved" object:nil];
            }
        }
    }];
}
- (IBAction)importdeck:(id)sender {
    NSOpenPanel * op = [NSOpenPanel openPanel];
    op.allowedFileTypes = @[@"csv", @"Comma Delimited Values File"];
    op.message = @"Please select a CSV file to import as a deck.";
    [op beginSheetModalForWindow:self.window
               completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        [op close];
        NSURL *Url = op.URL;
        self.csvic = [CSVImportController new];
        CSVDeckImporter *csvimporter = [CSVDeckImporter new];
        [csvimporter loadCSVWithURL:Url completionHandler:^(bool success, NSArray * _Nonnull columnnames) {
                if (success) {
                    [self.csvic.window makeKeyAndOrderFront:self];
                    [self.csvic loadColumnNames:columnnames];
                    [self.window beginSheet:self.csvic.window completionHandler:^(NSModalResponse returnCode) {
                        if (returnCode == NSModalResponseOK) {
                            [csvimporter performimportWithDeckName:self.csvic.deckname.stringValue withDeckType:self.csvic.decktype.selectedTag destinationMap:self.csvic.maparray completionHandler:^(bool success) {
                                if (success) {
                                    [NSNotificationCenter.defaultCenter postNotificationName:@"DeckAdded" object:nil];
                                    NSAlert *alert = [[NSAlert alloc] init] ;
                                    [alert addButtonWithTitle:@"OK"];
                                    [alert setMessageText:@"Deck imported"];
                                    alert.informativeText = @"Deck as successfully imported";
                                    alert.alertStyle = NSAlertStyleInformational;
                                    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                                        }];
                                }
                                else {
                                    NSAlert *alert = [[NSAlert alloc] init] ;
                                    [alert addButtonWithTitle:@"OK"];
                                    [alert setMessageText:@"Deck import failed"];
                                    alert.informativeText = @"Deck either already exists or the field mappings are not correctly set. Please try again.";
                                    alert.alertStyle = NSAlertStyleInformational;
                                    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                                        }];
                                }
                            }];
                        }
                    }];
                }
        }];
    }];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_arrayController mutableArrayValueForKey:@"content"].count;
}

#pragma mark NSTableViewDelegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    DeckViewCell *cell = [tableView makeViewWithIdentifier:@"deckviewcell" owner:self];
    NSManagedObject *deck = _arrayController.arrangedObjects[row];
    cell.DeckName.stringValue = [deck valueForKey:@"deckName"];
    cell.deckMeta = deck;
    [cell reloadQueueCount];
    [cell setDeckTypeLabel];
    return cell;
}

@end
