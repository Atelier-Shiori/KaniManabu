//
//  GeneralPreferencesViewController.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "GeneralPreferencesViewController.h"

@interface GeneralPreferencesViewController ()

@end

@implementation GeneralPreferencesViewController

- (instancetype)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
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
