//
//  GeneralPreferencesViewController.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "GeneralPreferencesViewController.h"

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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/kanimanabu/privacy-policy/"]];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageWithSystemSymbolName:@"gear" accessibilityDescription:@""];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"General", @"Toolbar item name for the General Preferences pane");
}

@end
