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

@end

@implementation GeneralPreferencesViewController

- (instancetype)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
}

- (IBAction)sendstatstoggle:(id)sender {
    [MSACCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
    [MSACAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
}
- (IBAction)viewprivacypolicy:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/privacy-policy/"]];
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
- (IBAction)playsample:(id)sender {
    [SpeechSynthesis.sharedInstance playSample];
}

@end
