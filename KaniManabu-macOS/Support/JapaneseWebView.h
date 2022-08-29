//
//  JapaneseWebView.h
//  KaniManabu
//
//  Created by 千代田桃 on 6/19/22.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface JapaneseWebView : NSViewController  <WKUIDelegate,WKNavigationDelegate>
@property (strong) WKWebView *webView;
- (void)loadHTMLFromFrontText:(NSString *)fronttext userandomfont:(bool)userandomfont;
- (void)loadHTMLFromFrontText:(NSString *)fronttext withBackText:(NSString *)backtext;
@end

