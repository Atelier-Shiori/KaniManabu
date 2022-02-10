//
//  GeneralPreferencesViewController.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "GeneralPreferencesViewController.h"
#import "DeckManager.h"
#import "SpeechSynthesis.h"

@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface GeneralPreferencesViewController ()
@property (strong) IBOutlet NSSecureTextField *msazureapikey;
@property (strong) IBOutlet NSButton *savebtn;
@property (strong) IBOutlet NSButton *clearbtn;

@end

@implementation GeneralPreferencesViewController

- (instancetype)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
}

- (void)awakeFromNib {
    [self checkAPIState];
}

- (IBAction)sendstatstoggle:(id)sender {
    [MSACCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
    [MSACAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
}
- (IBAction)viewprivacypolicy:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/kanimanabu/privacy-policy/"]];
}
- (IBAction)removeorphaned:(id)sender {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Remove Orphaned Cards?";
    alert.informativeText = @"Do you want to remove orphaned cards? Once done, it cannot be undone.";
    [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    if (@available(macOS 11.0, *)) {
        [(NSButton *)alert.buttons[0] setHasDestructiveAction:YES];
    } 
    [(NSButton *)alert.buttons[0] setKeyEquivalent: @""];
    [(NSButton *)alert.buttons[1] setKeyEquivalent: @"\033"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            ((NSButton *)sender).enabled = NO;
            [DeckManager.sharedInstance.moc performBlock:^{
                [DeckManager.sharedInstance removeOrphanedCards];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((NSButton *)sender).enabled = YES;
                });
            }];
        }
    }];
}

- (IBAction)clearapikey:(id)sender {
    [SpeechSynthesis.sharedInstance removeSubscriptionKey];
    [self checkAPIState];
}

- (IBAction)saveapi:(id)sender {
    if (_msazureapikey.stringValue.length > 0) {
        [SpeechSynthesis.sharedInstance storeSubscriptionKey:_msazureapikey.stringValue];
        _msazureapikey.stringValue = @"";
        [self checkAPIState];
    }
    else {
        NSBeep();
    }
}


- (void)checkAPIState {
    if ([SpeechSynthesis.sharedInstance getSubscriptionKey]) {
        _msazureapikey.enabled = NO;
        _savebtn.enabled = NO;
        _clearbtn.enabled = YES;
    }
    else {
        _msazureapikey.enabled = YES;
        _savebtn.enabled = YES;
        _clearbtn.enabled = NO;
    }
}

- (IBAction)showhelp:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://help.malupdaterosx.moe/kanimanabu/"]];
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"gear" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        return [NSImage imageNamed:@"gear"];
    }
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"General", @"Toolbar item name for the General Preferences pane");
}

@end
