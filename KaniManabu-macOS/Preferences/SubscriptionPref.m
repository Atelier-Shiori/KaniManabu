//
//  SubscriptionPref.m
//  KaniManabu
//
//  Created by 千代田桃 on 3/13/22.
//

#import "SubscriptionPref.h"
#import "SubscriptionManager.h"
#import "SubscriptionPickerWindow.h"

@interface SubscriptionPref ()
@property (strong) SubscriptionPickerWindow *spw;
@property (strong) IBOutlet NSTextField *subuuid;
@end

@implementation SubscriptionPref
- (instancetype)init
{
    return [super initWithNibName:@"SubscriptionPref" bundle:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSString *userid = [NSUbiquitousKeyValueStore.defaultStore stringForKey:@"RevenueCatUserID"];
    _subuuid.stringValue = [NSString stringWithFormat:@"Sub ID: %@", userid];
}
- (IBAction)subscribe:(id)sender {
    _spw = [SubscriptionPickerWindow new];
    [_spw.window makeKeyAndOrderFront:self];
    [_spw.window orderOut:self];
    [self.view.window beginSheet:_spw.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
        }
        else if (returnCode == NSModalResponseAbort) {
            NSAlert *alert = [[NSAlert alloc] init] ;
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Unable to load subscriptions metadata."];
            alert.informativeText = @"Make sure you are connected to the internet and try again.";
            alert.alertStyle = NSAlertStyleInformational;
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                }];
        }
    }];
}
- (IBAction)restorepurchase:(id)sender {
    [SubscriptionManager restorePurchase:^(bool success) {
        NSAlert *alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:success ? @"Subscription Restored" : @"Unable to Restore Subscription"];
        alert.informativeText = success ? @"Subscription successfully restored" : @"You don't have an active subscription";
        alert.alertStyle = NSAlertStyleInformational;
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            }];
    }];
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"SubscriptionPref";
}

- (NSImage *)toolbarItemImage {
        return [NSImage imageNamed:@"subscription"];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Subscription", @"Toolbar item name for the Subscription Preferences pane");
}
@end
