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
#import <UserNotifications/UserNotifications.h>

@interface DeckMonitor ()
@property (strong) DeckManager *dm;
@property bool syncdone;
@property bool timeractive;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong, nonatomic) MSWeakTimer *timer;
@property (strong) NSPersistentCloudKitContainer *persistentContainer;
@property (strong) NSDate *nextHistoryCheck;
@property bool firstsync;
@property bool firstsyncdone;
@property (strong) UNUserNotificationCenter *notificationCenter;
@end

@implementation DeckMonitor
- (instancetype)init {
    if (self = [super init]) {
        _dm = [DeckManager sharedInstance];
        self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
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
        if (!_firstsync) {
            _firstsync = YES;
            [self notifyLaunchSync];
        }
        _syncdone = NO;
        _syncinginprogress = YES;
        [self startsynctimer];
        _syncinginprogress = NO;
    }
    else {
        [self startsynctimer];
    }
}

- (void)setCardTotals {
    _previousdeckcount = [_dm retrieveDecks].count;
    _totalcardcount = [_dm retrieveAllCardswithPredicate:nil].count;
    _totalreviewqueuecount = [_dm retrieveAllReviewItems].count;
    _totallearnqueuecount = [_dm getAllLearnItems].count;
}

- (bool)cardtotalschanged {
    long ndeckcount = [_dm retrieveDecks].count;
    long ntotalcardcount = [_dm retrieveAllCardswithPredicate:nil].count;
    long ntotalreviewqueuecount = [_dm retrieveAllReviewItems].count;
    long ntotallearnqueuecount = [_dm getAllLearnItems].count;
    return ndeckcount != _previousdeckcount || ntotalcardcount != _totalcardcount || ntotalreviewqueuecount != _totalreviewqueuecount || ntotallearnqueuecount != _totallearnqueuecount;
}

- (void)setNewCards {
    NSArray *decks = [_dm retrieveDecks];
    for (NSManagedObject *deck in decks) {
        NSDate *nextdate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[deck valueForKey:@"nextLearnInterval"]).doubleValue];
        if (nextdate.timeIntervalSinceNow <= 0) {
            [_dm setandretrieveLearnItemsForDeckUUID:[deck valueForKey:@"deckUUID"] withType:((NSNumber *)[deck valueForKey:@"deckType"]).intValue];
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
    if (!_firstsyncdone) {
        _firstsyncdone = YES;
        [self notifySyncDone];
    }
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

- (void)notifyLaunchSync {
    [self showNotificationWithMessage:@"KaniManabu is syncing from iCloud since it last launched. Please wait for it to complete with a notification before reviewing/learning items."];
}

- (void)notifySyncDone {
    [self showNotificationWithMessage:@"KaniManabu has finished syncing. You may begin reviewing/learning items."];
}

- (void)showNotificationWithMessage:(NSString *)message {
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"KaniManabu";
    content.body = message;
    content.sound = [UNNotificationSound defaultSound];
    NSDateComponents *triggerDate = [[NSCalendar currentCalendar]
                                     components:NSCalendarUnitYear +
                                     NSCalendarUnitMonth + NSCalendarUnitDay +
                                     NSCalendarUnitHour + NSCalendarUnitMinute +
                                     NSCalendarUnitSecond fromDate:[NSDate.date dateByAddingTimeInterval:3]];
    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:triggerDate
                            repeats:NO];
    NSString *identifier = [NSString stringWithFormat:@"kanimanabu-sync-%.f",NSDate.date.timeIntervalSince1970];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                          content:content
                                                                          trigger:trigger];
    [_notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
        }
        else {
            NSLog(@"Successfully scheduled notification: %@", identifier);
        }
    }];
}

@end
