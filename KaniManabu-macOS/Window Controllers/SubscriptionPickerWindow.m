//
//  SubscriptionPickerWindow.m
//  KaniManabu (AppStore)
//
//  Created by 千代田桃 on 3/14/22.
//

#import "SubscriptionPickerWindow.h"
#import "SubscriptionManager.h"

@interface SubscriptionPickerWindow ()
@property (strong) IBOutlet NSButton *monthly;
@property (strong) IBOutlet NSButton *yearly;
@property (strong) IBOutlet NSButton *lifetime;
@property (strong) IBOutlet NSButton *subscribebtn;
@property (strong) IBOutlet NSButton *cancelbtn;
@property (strong) IBOutlet NSProgressIndicator *indicator;
@property (strong) RCOffering *offeringsdefault;
@end

@implementation SubscriptionPickerWindow
- (instancetype)init {
    self = [super initWithWindowNibName:@"SubscriptionPickerWindow"];
    if (!self)
        return nil;
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [SubscriptionManager getOfferingsWithcompletionHandler:^(bool success, RCOfferings * _Nonnull offerings) {
        if (success) {
            self.offeringsdefault = offerings.all[@"default"];
            self.monthly.title = [NSString stringWithFormat:@"Monthly - %@" , self.offeringsdefault.monthly.localizedPriceString];
            self.yearly.title = [NSString stringWithFormat:@"Yearly - %@" , self.offeringsdefault.annual.localizedPriceString];
            self.lifetime.title = [NSString stringWithFormat:@"Lifetime - %@" , self.offeringsdefault.lifetime.localizedPriceString];
        }
        else {
            [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseAbort];
            [self.window close];
        }
    }];
}

- (void)indicatorActive:(bool)active {
    if (active) {
        _subscribebtn.enabled = NO;
        _cancelbtn.enabled = NO;
        _indicator.hidden = NO;
        _monthly.enabled = NO;
        _yearly.enabled = NO;
        _lifetime.enabled = NO;
        [_indicator startAnimation:self];
    }
    else {
        _subscribebtn.enabled = YES;
        _cancelbtn.enabled = YES;
        _indicator.hidden = YES;
        _monthly.enabled = YES;
        _yearly.enabled = YES;
        _lifetime.enabled = YES;
        [_indicator stopAnimation:self];
    }
}
- (IBAction)monthlyselect:(id)sender {
    _monthly.state = NSControlStateValueOn;
    _yearly.state = NSControlStateValueOff;
    _lifetime.state = NSControlStateValueOff;
}

- (IBAction)yearlyselect:(id)sender {
    _monthly.state = NSControlStateValueOff;
    _yearly.state = NSControlStateValueOn;
    _lifetime.state = NSControlStateValueOff;
}

- (IBAction)lifetimeselect:(id)sender {
    _monthly.state = NSControlStateValueOff;
    _yearly.state = NSControlStateValueOff;
    _lifetime.state = NSControlStateValueOn;
}


- (IBAction)subscribe:(id)sender {
    RCPackage *package;
    [self indicatorActive:YES];
    if (_monthly.state == NSControlStateValueOn) {
        package = _offeringsdefault.monthly;
    }
    else if (_yearly.state == NSControlStateValueOn) {
        package = _offeringsdefault.annual;
    }
    else if (_lifetime.state == NSControlStateValueOn) {
        package = _offeringsdefault.lifetime;
    }
    else {
        [self indicatorActive:NO];
        return;
    }
    [SubscriptionManager purchasePackage:package completionHandler:^(bool success, bool cancelled) {
        if (success && !cancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self indicatorActive:NO];
                [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
                [self.window close];
            });
        }
        else {
            [self indicatorActive:NO];
        }
    }];
}
- (IBAction)cancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    [self.window close];
}
- (IBAction)privacypolicy:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/terms-of-use/"]];
}
- (IBAction)termsofservice:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://kanimanabu.app/privacy-policy/"]];
}

@end
