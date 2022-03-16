//
//  AdvancedPref.m
//  KaniManabu
//
//  Created by 千代田桃 on 3/16/22.
//

#import "AdvancedPref.h"
#import "SpeechSynthesis.h"

@interface AdvancedPref ()
@property (strong) IBOutlet NSSecureTextField *msazureapikey;
@property (strong) IBOutlet NSButton *savebtn;
@property (strong) IBOutlet NSButton *clearbtn;
@property (strong) IBOutlet NSSecureTextField *ibmapikey;
@property (strong) IBOutlet NSTextField *ibmurl;
@property (strong) IBOutlet NSButton *ibmclear;
@property (strong) IBOutlet NSButton *ibmsavebtn;
@end

@implementation AdvancedPref
- (instancetype)init
{
    return [super initWithNibName:@"AdvancedPref" bundle:nil];
}

- (void)awakeFromNib {
    [self checkAPIState];
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

- (IBAction)clearibmapikey:(id)sender {
    [SpeechSynthesis.sharedInstance removeIBMAPIKey];
    [self checkAPIState];
}

- (IBAction)saveibmapi:(id)sender {
    if (_ibmurl.stringValue.length > 0 && _ibmapikey.stringValue.length > 0) {
        [SpeechSynthesis.sharedInstance storeIBMAPIKey:@{@"apikey" : _ibmapikey.stringValue, @"url" : _ibmurl.stringValue}];
        _ibmapikey.stringValue = @"";
        _ibmurl.stringValue = @"";
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
    if ([SpeechSynthesis.sharedInstance getIBMAPIKey]) {
        _ibmapikey.enabled = NO;
        _ibmurl.enabled = NO;
        _ibmsavebtn.enabled = NO;
        _ibmclear.enabled = YES;
    }
    else {
        _ibmapikey.enabled = YES;
        _ibmurl.enabled = YES;
        _ibmsavebtn.enabled = YES;
        _ibmclear.enabled = NO;
    }
}

- (IBAction)showhelp:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://help.malupdaterosx.moe/kanimanabu/"]];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage {
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"gearshape.2" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        return [NSImage imageNamed:@"advanced"];
    }
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}
@end
