//
//  DeckMonitor.m
//  KaniManabu
//
//  Created by 千代田桃 on 2/14/22.
//

#import "DeckMonitor.h"
#import "DeckManager.h"
#import "AppDelegate.h"
#import "MSWeakTimer.h"

@interface DeckMonitor ()
@property bool syncdone;
@property bool timeractive;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong, nonatomic) MSWeakTimer *timer;
@property (strong) NSPersistentCloudKitContainer *persistentContainer;
@property (strong) NSDate *nextHistoryCheck;
@end

@implementation DeckMonitor
- (instancetype)init {
    if (self = [super init]) {
        AppDelegate *delegate = (AppDelegate *)NSApp.delegate;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreRemoteChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:delegate.persistentContainer.persistentStoreCoordinator];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"NSPersistentStoreRemoteChangeNotification" object:delegate.persistentContainer.persistentStoreCoordinator];
        _privateQueue = dispatch_queue_create("moe.ateliershiori.KaniManabu.DeckMonitor", DISPATCH_QUEUE_CONCURRENT);
        _persistentContainer = delegate.persistentContainer;
        [self setCardTotals];
        return self;
    }
    return nil;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)receiveNotification:(NSNotification *)notification {
    NSLog(@"Notification Name: %@",notification.name);
    if (!_syncinginprogress) {
        _syncdone = NO;
        _syncinginprogress = YES;
        [self startsynctimer];
        [self monitorsync];
        _syncinginprogress = NO;
    }
    else {
        [self startsynctimer];
    }
}

- (void)monitorsync {
    NSLog(@"Monitoring...");
    while (!_syncdone) {
        sleep(5);
    }
    NSLog(@"Sync Done");
    bool changesindatabase = [self checkTransactionHistory];
    if ([self cardtotalschanged] || changesindatabase) {
        NSLog(@"New Items detected...");
        [NSNotificationCenter.defaultCenter postNotificationName:@"NewItemsSynced" object:nil];
        [self setCardTotals];
        if (changesindatabase) {
            [NSUserDefaults.standardUserDefaults setValue:NSDate.date forKey:@"LastLaunchSyncDate"];
        }
    }
    [self setNewCards];
}

- (void)setCardTotals {
    _previousdeckcount = [DeckManager.sharedInstance retrieveDecks].count;
    _totalcardcount = [DeckManager.sharedInstance retrieveAllCardswithPredicate:nil].count;
    _totalreviewqueuecount = [DeckManager.sharedInstance retrieveAllReviewItems].count;
    _totallearnqueuecount = [DeckManager.sharedInstance getAllLearnItems].count;
}

- (bool)cardtotalschanged {
    long ndeckcount = [DeckManager.sharedInstance retrieveDecks].count;
    long ntotalcardcount = [DeckManager.sharedInstance retrieveAllCardswithPredicate:nil].count;
    long ntotalreviewqueuecount = [DeckManager.sharedInstance retrieveAllReviewItems].count;
    long ntotallearnqueuecount = [DeckManager.sharedInstance getAllLearnItems].count;
    return ndeckcount != _previousdeckcount || ntotalcardcount != _totalcardcount || ntotalreviewqueuecount != _totalreviewqueuecount || ntotallearnqueuecount != _totallearnqueuecount;
}

- (void)setNewCards {
    NSArray *decks = [DeckManager.sharedInstance retrieveDecks];
    for (NSManagedObject *deck in decks) {
        NSDate *nextdate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[deck valueForKey:@"nextLearnInterval"]).doubleValue];
        if (nextdate.timeIntervalSinceNow <= 0) {
            [DeckManager.sharedInstance setandretrieveLearnItemsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
        }
    }
}

- (void)startsynctimer {
    if (_timeractive) {
        NSLog(@"Resetting Timer");
        [_timer invalidate];
    }
    else {
        NSLog(@"Starting Timer");
        _timeractive = YES;
    }
    _timer =  [MSWeakTimer scheduledTimerWithTimeInterval:30
                                                          target:self
                                                 selector:@selector(firetimer)
                                                        userInfo:nil
                                                         repeats:NO
                                                   dispatchQueue:_privateQueue];
}

- (void)firetimer {
    _syncdone = YES;
    _timeractive = NO;
}

- (bool)checkTransactionHistory {
    if (_nextHistoryCheck) {
        if (_nextHistoryCheck.timeIntervalSinceNow >= 0){
            return false;
        }
    }
    NSDate *lastdate = [NSUserDefaults.standardUserDefaults valueForKey:@"LastLaunchSyncDate"];
    int changecount = 0;
    if (lastdate) {
        @try {
            NSPersistentHistoryChangeRequest *fetchHistoryRequest = [NSPersistentHistoryChangeRequest fetchHistoryAfterDate:lastdate];
            NSManagedObjectContext *moc = _persistentContainer.viewContext;
            __block NSPersistentHistoryResult *hresult;
            [moc performBlockAndWait:^{
                hresult = [moc executeRequest:fetchHistoryRequest error:nil];
            }];
            NSArray *historyresults = hresult.result;
            for (int i = (int)historyresults.count - 1; i >= 0; i--) {
                NSPersistentHistoryTransaction *transaction = historyresults[i];
                if (transaction.changes.count > 0) {
                    changecount++;
                }
            }
            _nextHistoryCheck = [NSDate.date dateByAddingTimeInterval:300];
            return changecount > 0;
        }
        @catch (NSException *ex) {}
    }
    return false;
}
@end
