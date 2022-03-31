//
//  WaniKaniPreferences.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/24/22.
//

#import "WaniKaniPreferences.h"
#import "WaniKani.h"

@interface WaniKaniPreferences ()
@property (strong) IBOutlet NSSecureTextField *apikey;
@property (strong) IBOutlet NSButton *savebtn;
@property (strong) IBOutlet NSButton *clearbtn;
@property (strong) IBOutlet NSTextField *wanikaniusername;
@property (strong) IBOutlet NSTextField *wanikanisubscribed;

@end

@implementation WaniKaniPreferences
- (instancetype)init
{
    return [super initWithNibName:@"WaniKaniPreferences" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setbuttons];
    [self loadUserInformation];
}
- (IBAction)save:(id)sender {
    [WaniKani.sharedInstance checkToken:_apikey.stringValue completionHandler:^(bool success) {
        if (success) {
            [WaniKani.sharedInstance saveToken:self.apikey.stringValue];
            [WaniKani.sharedInstance refreshUserInformationWithcompletionHandler:^(bool success) {
                if (success) {
                    [self setbuttons];
                    [self loadUserInformation];
                    self.apikey.stringValue = @"";
                }
                else {
                    [WaniKani.sharedInstance removeToken];
                }
            }];
        }
        else {
            NSAlert *alert = [[NSAlert alloc] init] ;
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Invalid API Token"];
            alert.informativeText = @"The API token you entered was invalid. Please try again.";
            alert.alertStyle = NSAlertStyleInformational;
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                }];
        }
    }];
}

- (IBAction)clear:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    alert.messageText = @"Do you want to log out?";
    alert.informativeText = @"Once you logged out, you need to log back in before you can use WaniKani features.";
    // Set Message type to Warning
    alert.alertStyle = NSAlertStyleWarning;
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [WaniKani.sharedInstance removeToken];
            [self setbuttons];
            [self loadUserInformation];
        }
    }];
}


- (void)setbuttons {
    if ([WaniKani.sharedInstance getToken]) {
        _apikey.enabled = false;
        _savebtn.enabled = false;
        _clearbtn.enabled = true;
    }
    else {
        _apikey.enabled = true;
        _savebtn.enabled = true;
        _clearbtn.enabled = false;
    }
}

- (void)loadUserInformation {
    if ([WaniKani.sharedInstance getToken]) {
        _wanikaniusername.stringValue = [NSUserDefaults.standardUserDefaults valueForKey:@"WaniKaniUsername"];
        _wanikanisubscribed.stringValue = [NSUserDefaults.standardUserDefaults valueForKey:@"WaniKaniSubscribed"] ? @"Full" : @"Limited";
    }
    else {
        _wanikaniusername.stringValue = @"N/A";
        _wanikanisubscribed.stringValue = @"N/A";
    }
}

- (IBAction)getapitoken:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.wanikani.com/settings/personal_access_tokens"]];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"WaniKaniPreferences";
}

- (NSImage *)toolbarItemImage {
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"tortoise" accessibilityDescription:@""];
    } else {
        // Fallback on earlier versions
        return [NSImage imageNamed:@"turtle"];
    }
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"WaniKani", @"Toolbar item name for the WaniKani Preferences pane");
}
@end
