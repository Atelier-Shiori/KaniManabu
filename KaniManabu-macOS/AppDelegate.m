//
//  AppDelegate.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "PreferencesControllers.h"
#import "DeckManager.h"
#import "PFAboutWindowController.h"
#import "WaniKani.h"
#import "SpeechSynthesis.h"
#import "DeckMonitor.h"

#if defined(AppStore)
#import "SubscriptionManager.h"
#else
#import "LicenseManager.h"
#endif

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate ()

@property PFAboutWindowController *aboutWindowController;
@property (strong) DeckMonitor *deckMonitor;
#if defined(AppStore)
@property (strong) RCPurchases *rcpurchases;
#endif
- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

NSString *const kcurrentDeckVersion = @"1";

+ (void)initialize {
    //Create a Dictionary
    NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
    
    // Defaults
    defaultValues[@"DeckNewCardLimitPerDay"] = @(5);
    defaultValues[@"SayKanaReadingAnswer"] = @YES;
    defaultValues[@"sendanalytics"] = @NO;
    defaultValues[@"ttsvoice"] = @(0);
    defaultValues[@"usekanjitts"] = @NO;
    defaultValues[@"usekanimanabuime"] = @YES;
    defaultValues[@"donated"] = @NO;
    //Register Dictionary
    [[NSUserDefaults standardUserDefaults]
     registerDefaults:defaultValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self checkDeckVersion];
    if (![DeckManager.sharedInstance checkiCloudLoggedIn]) {
        [self showiCloudNotice];
    }
    DeckManager.sharedInstance.moc = self.persistentContainer.viewContext;
    WaniKani.sharedInstance.moc = self.wanikaniContainer.viewContext;
    SpeechSynthesis.sharedInstance.moc = self.audioContainer.viewContext;
    _deckMonitor = [DeckMonitor new];
    _mwc = [MainWindowController new];
    _mwc.moc = DeckManager.sharedInstance.moc;
    
    if ([WaniKani.sharedInstance getToken]) {
        [WaniKani.sharedInstance refreshUserInformationWithcompletionHandler:^(bool success) {}];
    }

    [_mwc.window makeKeyAndOrderFront:self];
    
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionBadge|UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"User enabled badges");
        }
    }];
    
    [MSACAppCenter start:@"8dbff13f-197a-40f6-800c-e70eb45f1fb7" withServices:@[
      [MSACAnalytics class],
      [MSACCrashes class]
    ]];
    [MSACCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
    [MSACAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
#if defined(AppStore)
    NSString *userid = [NSUbiquitousKeyValueStore.defaultStore objectForKey:@"RevenueCatUserID"];
    if (!userid) {
        // Set key in iCloud for RevenueCat to use
        userid = [NSUUID new].UUIDString;
        [NSUbiquitousKeyValueStore.defaultStore setString:userid forKey:@"RevenueCatUserID"];
        [NSUbiquitousKeyValueStore.defaultStore synchronize];
    }
    _rcpurchases = [RCPurchases configureWithAPIKey:@"appl_tSCAgCTfPHikGbKqyzZgHXxBVcC" appUserID:userid];
    RCPurchases.logLevel = RCLogLevelDebug;
    _rcpurchases.delegate = self;
    [SubscriptionManager getCustomerInfo:^(bool success, RCCustomerInfo * customerInfo) {
        if (customerInfo) {
            [SubscriptionManager setDonationStateWithCustomer:customerInfo];
        }
        if (![NSUserDefaults.standardUserDefaults boolForKey:@"donated"]) {
            [self showNagDialogWithWindow:self.mwc.window];
        }
    }];
#else
    [LicenseManager.sharedInstance checkLicenseWithWindow:_mwc.window];
#endif
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}
- (IBAction)enterLicense:(id)sender {
#if defined(AppStore)
#else
    [LicenseManager.sharedInstance showLicenceEnterWindow];
#endif
}

- (NSWindowController *)preferencesWindowController {
    if (__preferencesWindowController == nil)
    {
        GeneralPreferencesViewController *genview = [[GeneralPreferencesViewController  alloc] init];
        WaniKaniPreferences *wpref = [WaniKaniPreferences new];
        AdvancedPref *apref = [AdvancedPref new];
#if defined(AppStore)
        SubscriptionPref *subpref = [SubscriptionPref new];
        NSArray *controllers = @[genview,wpref,subpref, apref];
#else
        SoftwareUpdatesPref *supref = [SoftwareUpdatesPref new];
        NSArray *controllers = @[genview, wpref, supref, apref];
#endif
        __preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return __preferencesWindowController;
}
- (IBAction)viewPreferences:(id)sender {
    [self.preferencesWindowController showWindow:nil];
}

- (IBAction)showaboutwindow:(id)sender{
    if (!_aboutWindowController) {
        _aboutWindowController = [PFAboutWindowController new];
    }
    (self.aboutWindowController).appURL = [[NSURL alloc] initWithString:@"https://kanimanabu.app"];
    NSMutableString *copyrightstr = [NSMutableString new];
    NSDictionary *bundleDict = [NSBundle mainBundle].infoDictionary;
    [copyrightstr appendFormat:@"%@ \r\r",bundleDict[@"NSHumanReadableCopyright"]];
#if defined(AppStore)
#if defined(OSS)
    [copyrightstr appendString:@"Community version. No support will be provided."];
#else
    [copyrightstr appendString:@"Mac App Store version."];
#endif
#else
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"donated"] && [NSUserDefaults.standardUserDefaults boolForKey:@"activepatron"]) {
                [copyrightstr appendString:@"Registered. Thank you for supporting KaniManabu's development through Patreon!"];
    }
    else if (((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]).boolValue) {
        [copyrightstr appendString:@"Registered. Thank you for supporting Kanimanabu's development!"];
        [copyrightstr appendFormat:@"\rThis copy is registered to: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
    }
    else {
        [copyrightstr appendString:@"UNREGISTERED."];
    }
#endif
    (self.aboutWindowController).appCopyright = [[NSAttributedString alloc] initWithString:copyrightstr
                                                                                attributes:@{
                                                                                             NSForegroundColorAttributeName:[NSColor labelColor],
                                                                                             NSFontAttributeName:[NSFont fontWithName:[NSFont systemFontOfSize:12.0f].familyName size:11]}];
    
    [self.aboutWindowController showWindow:nil];
}

- (IBAction)reportIssue:(id)sender{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.malupdaterosx.moe/index.php?forums/kanimanabu-bug-tracker.23/"]];
}

- (IBAction)showhelp:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://help.malupdaterosx.moe/kanimanabu/"]];
}

- (IBAction)showtos:(id)sender{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/terms-of-use/"]];
}

- (IBAction)showprivacypolicy:(id)sender{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/privacy-policy/"]];
}

- (IBAction)showresources:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/resources/"]];
}

- (IBAction)showjapaneseinputguide:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/wp-content/uploads/sites/3/2022/04/typingjapaneseguide.pdf"]];
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;
@synthesize wanikaniContainer = _wanikaniContainer;
@synthesize audioContainer = _audioContainer;

- (NSPersistentCloudKitContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentCloudKitContainer alloc] initWithName:@"KaniManabu"];
            _persistentContainer.viewContext.automaticallyMergesChangesFromParent = YES;
            NSPersistentStoreDescription *description = _persistentContainer.persistentStoreDescriptions.firstObject;
            [description setOption:@YES forKey:NSPersistentHistoryTrackingKey];
            [description setOption:@YES forKey:NSPersistentStoreRemoteChangeNotificationPostOptionKey];
            [description setOption:@YES forKey:@"NSPersistentStoreRemoteChangeNotificationOptionKey"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

- (NSPersistentContainer *)wanikaniContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_wanikaniContainer == nil) {
            _wanikaniContainer = [[NSPersistentContainer alloc] initWithName:@"WaniKani"];
            [_wanikaniContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _wanikaniContainer;
}

- (NSPersistentContainer *)audioContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_audioContainer == nil) {
            _audioContainer = [[NSPersistentContainer alloc] initWithName:@"AudioContainer"];
            [_audioContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _audioContainer;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    NSManagedObjectContext *context = self.persistentContainer.viewContext;

    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if (context.hasChanges && ![context save:&error]) {
        // Customize this code block to include application-specific recovery steps.              
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return self.persistentContainer.viewContext.undoManager;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save current date for use with history tracking
    [NSUserDefaults.standardUserDefaults setValue:NSDate.date forKey:@"LastLaunchSyncDate"];
    // Save changes in the application's managed object context before the application terminates.
    NSManagedObjectContext *context = self.persistentContainer.viewContext;

    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!context.hasChanges) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![context save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    NSManagedObjectContext *wcontext = self.wanikaniContainer.viewContext;

    if (![wcontext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!wcontext.hasChanges) {
        return NSTerminateNow;
    }
    
    if (![wcontext save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    NSManagedObjectContext *acontext = self.audioContainer.viewContext;

    if (![acontext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!acontext.hasChanges) {
        return NSTerminateNow;
    }
    
    if (![acontext save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) {
            return NSTerminateCancel;
        }
    }


    return NSTerminateNow;
}

#pragma mark RevenueCat
#if defined(AppStore)
- (void)purchases:(RCPurchases *)purchases receivedUpdatedCustomerInfo:(RCCustomerInfo *)customerInfo {
    [SubscriptionManager setDonationStateWithCustomer:customerInfo];
}

- (void)showNagDialogWithWindow:(NSWindow *)w {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Please Support KaniManabu";
    alert.informativeText = @"While KaniManabu is free to use, you are limited to three decks and this message will appear on launch. To remove this limitation and this nag message while unlocking subscriber features, get a subscription. Do you want to open Preferences to view Subscription options?";
    [alert addButtonWithTitle:NSLocalizedString(@"Subscribe",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Not Now",nil)];
    [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self.preferencesWindowController showWindow:nil];
            [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:2];
        }
    }];
}
#else
#endif

#pragma mark iCloud Not Logged in Warning
- (void)showiCloudNotice {
    // Shows Donation Reminder
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool show = ![defaults valueForKey:@"surpressicloudnotice"];
    if (![defaults boolForKey:@"surpressicloudnotice"] || show) {
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"OK"];
        alert.messageText = @"Not Logged into iCloud or iCloud Drive Disabled";
        alert.informativeText = @"KaniManabu relies on iCloud Drive and iCloud Account for the app to fully function. Make sure you are logged into an iCloud Account and have iCloud Drive enabled and relaunch the app. Some functionality is now limited.";
        [alert setShowsSuppressionButton:YES];
        // Set Message type to Warning
        alert.alertStyle = NSAlertStyleInformational;
        long choice = [alert runModal];
        if (alert.suppressionButton.state == NSControlStateValueOn) {
            // Suppress this alert until the next version
            [defaults setBool: YES forKey:@"surpressicloudnotice"];
        }
    }
}

- (void)checkDeckVersion {
    NSString *deckversion = [NSUbiquitousKeyValueStore.defaultStore objectForKey:@"DeckVersion"];
    if (!deckversion) {
        [NSUbiquitousKeyValueStore.defaultStore setString:kcurrentDeckVersion forKey:@"DeckVersion"];
        [NSUbiquitousKeyValueStore.defaultStore synchronize];
    }
    if (deckversion.doubleValue < kcurrentDeckVersion.doubleValue) {
        [NSUbiquitousKeyValueStore.defaultStore setString:kcurrentDeckVersion forKey:@"DeckVersion"];
        [NSUbiquitousKeyValueStore.defaultStore synchronize];
        NSLog(@"Set new deck version");
    }
    else if (deckversion.doubleValue > kcurrentDeckVersion.doubleValue) {
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"OK"];
        alert.messageText = @"KaniManabu Client Too Old";
#if defined(AppStore)
        alert.informativeText = @"This version of KaniManabu is too old and not compatible with the deck stored on iCloud. Please open the App Store and update to the latest client. This application will now quit.";
#else
        alert.informativeText = @"This version of KaniManabu is too old and not compatible with the deck stored on iCloud. Please download the latest version. This application will now quit.";
#endif
        // Set Message type to Warning
        alert.alertStyle = NSAlertStyleInformational;
        long choice = [alert runModal];
#if defined(AppStore)
#else
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/downloadkanimanabu.php"]];
#endif
        [[NSApplication sharedApplication] terminate:nil];
    }

}
@end
