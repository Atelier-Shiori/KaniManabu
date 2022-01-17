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

#if defined(AppStore)
#else
#import "LicenseManager.h"
#endif

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate ()

@property PFAboutWindowController *aboutWindowController;
- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

+ (void)initialize {
    //Create a Dictionary
    NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
    
    // Defaults
    defaultValues[@"DeckNewCardLimitPerDay"] = @(5);
    defaultValues[@"SayKanaReadingAnswer"] = @YES;
    defaultValues[@"sendanalytics"] = @YES;
#if defined(AppStore)
    defaultValues[@"donated"] = @YES;
#else
    defaultValues[@"donated"] = @NO;
#endif
    //Register Dictionary
    [[NSUserDefaults standardUserDefaults]
     registerDefaults:defaultValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    DeckManager.sharedInstance.moc = self.persistentContainer.viewContext;
    _mwc = [MainWindowController new];
    _mwc.moc = DeckManager.sharedInstance.moc;

    [_mwc.window makeKeyAndOrderFront:self];
    
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError * _Nullable error) {
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
        GeneralPreferencesViewController *genview =[[GeneralPreferencesViewController  alloc] init];
#if defined(AppStore)
        NSArray *controllers = @[genview];
#else
        SoftwareUpdatesPref *supref = [SoftwareUpdatesPref new];
        NSArray *controllers = @[genview, supref];
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
    (self.aboutWindowController).appURL = [[NSURL alloc] initWithString:@"https://malupdaterosx.moe/kanimanabu/"];
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

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

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

    return NSTerminateNow;
}

@end
