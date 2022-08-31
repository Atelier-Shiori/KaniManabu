//
//  JapaneseWebView.m
//  KaniManabu
//
//  Created by 千代田桃 on 6/19/22.
//

#import "JapaneseWebView.h"

@implementation JapaneseWebView
- (void)loadView {
    // Sets up Web View for Custom Decks
    WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:webConfiguration];
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    self.view = _webView;
    _webView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    // Set background transparent
    _webView.wantsLayer = true;
    _webView.layer.backgroundColor = NSColor.clearColor.CGColor;
    _webView.enclosingScrollView.backgroundColor = NSColor.clearColor;
    [_webView setValue:@YES forKey:@"drawsTransparentBackground"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (void)loadHTMLFromFrontText:(NSString *)fronttext userandomfont:(bool)userandomfont {
    // Loads Front Test (Question)
    NSString *htmltext;
    NSArray *fontsarray = [NSUserDefaults.standardUserDefaults valueForKey:@"fontnames"];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"cyclefonts"] && fontsarray.count > 0 && userandomfont) {
        htmltext = [NSString stringWithFormat:@"<html><head><meta charset=\"UTF-8\"><style>@media (prefers-color-scheme: dark){.content{color: #fff;}}.content{display: flex; justify-content: center; align-items: center; text-align: center; min-height: 100vh;font-family: \"%@\",-apple-system;font-size: 6em;}.content:hover{font-family: -apple-system, BlinkMacSystemFont, Helvetica, sans-serif, \"Apple Color Emoji\";}@media only screen and (max-width: 515px){.content{font-size: 4em;}]</style></head><body><div class=\"content\"><p>%@</p></div></body></html>", fontsarray[arc4random_uniform((int)fontsarray.count-1)], fronttext];
    }
    else {
        htmltext = [NSString stringWithFormat:@"<html><head><meta charset=\"UTF-8\"><style>@media (prefers-color-scheme: dark){.content{color: #fff;}}.content{display: flex; justify-content: center; align-items: center; text-align: center; min-height: 100vh;font-family: -appl e-system, BlinkMacSystemFont, Helvetica, sans-serif, \"Apple Color Emoji\";font-size: 6em;}@media only screen and (max-width: 515px){.content{font-size: 4em;}]</style></head><body><div class=\"content\"><p>%@</p></div></body></html>", fronttext];
    }
    [_webView loadHTMLString:htmltext baseURL:nil];
}

- (void)loadHTMLFromFrontText:(NSString *)fronttext withBackText:(NSString *)backtext {
    //Loads back notes
    NSString *htmltext = [NSString stringWithFormat:@"<html><head><meta charset=\"UTF-8\"><style>@media (prefers-color-scheme: dark){.content{color: #fff;}}.content{display: flex; justify-content: center; align-items: center; text-align: center; padding-top: 50px;padding-bottom: 50px;font-family: -apple-system, BlinkMacSystemFont, Helvetica, sans-serif, \"Apple Color Emoji\";font-size: 5em;}@media only screen and (max-width: 499px){.content{font-size: 2.5em;}]</style></head><body><div class=\"content\">%@</div><hr><div class=\"content\">%@</div></body></html>", fronttext, backtext];
    [_webView loadHTMLString:htmltext baseURL:nil];
}
@end
