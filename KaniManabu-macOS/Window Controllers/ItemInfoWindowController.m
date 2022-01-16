//
//  ItemInfoWindowController.m
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "ItemInfoWindowController.h"
#import "NSString+HTMLtoNSAttributedString.h"
#import "NSTextView+SetHTMLAttributedText.h"
#import <AVFoundation/AVFoundation.h>
#import "DeckManager.h"

@interface ItemInfoWindowController ()
@property (strong) IBOutlet NSTextField *wordlabel;
@property (strong) IBOutlet NSTextView *infotextview;
@property (strong) IBOutlet NSToolbarItem *playvoicetoolbaritem;

@end

@implementation ItemInfoWindowController
- (instancetype)init {
    self = [super initWithWindowNibName:@"ItemInfoWindow"];
    if (!self)
        return nil;
    return self;
}

- (void)setDictionary:(NSDictionary *)dictionary withWindowType:(ParentWindowType)wtype {
    _parentWindowType = wtype;
    _cardMeta = dictionary;
    [self populateValues];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"CardRemoved" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"CardModified" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"CardBrowserClosed" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"ReviewAdvanced" object:nil];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"CardRemoved"]) {
        if (_cardUUID == notification.object) {
            [self.window close];
        }
    }
    else if ([notification.name isEqualToString:@"ReviewAdvanced"]||[notification.name isEqualToString:@"CardBrowserClosed"]) {
        [self.window close];
    }
    else if ([notification.name isEqualToString:@"CardModified"]||[notification.name isEqualToString:NSPersistentStoreRemoteChangeNotification]) {
        if (_cardUUID == notification.object) {
            _cardMeta = [DeckManager.sharedInstance getCardWithCardUUID:_cardUUID withType:_cardType];
            [self populateValues];
        }
    }
}

- (void)populateValues {
    _cardUUID = _cardMeta[@"carduuid"];
    _cardType = ((NSNumber *)_cardMeta[@"cardtype"]).intValue;
    _wordlabel.stringValue = _cardMeta[@"japanese"];
    if (_cardType == DeckTypeKanji) {
        _playvoicetoolbaritem.enabled = false;
    }
    else {
        _playvoicetoolbaritem.enabled = true;
    }
    [self populateInfoSection];
}

- (void)populateInfoSection {
    NSMutableString *infostr = [NSMutableString new];
    switch (_cardType) {
        case DeckTypeKana: {
                [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",_cardMeta[@"english"]];
                if (((NSString *)_cardMeta[@"altmeaning"]).length > 0) {
                    [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",_cardMeta[@"altmeaning"]];
                }
            if (_cardMeta[@"notes"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",_cardMeta[@"notes"]];
                }
            }
                if (_cardMeta[@"contextsentence1"] != [NSNull null] && _cardMeta[@"englishsentence1"] != [NSNull null]) {
                    if (((NSString *)_cardMeta[@"contextsentence1"]).length > 0 && ((NSString *)_cardMeta[@"englishsentence1"]).length > 0) {
                        [infostr appendString:@"<h1>Example Sentences</h1>"];
                        [infostr appendFormat:@"<p>%@<br />%@</p>",_cardMeta[@"contextsentence1"],_cardMeta[@"englishsentence1"]];
                    }
                }
                if (_cardMeta[@"contextsentence2"] != [NSNull null] && _cardMeta[@"englishsentence2"] != [NSNull null]) {
                    if (((NSString *)_cardMeta[@"contextsentence2"]).length > 0 && ((NSString *)_cardMeta[@"englishsentence2"]).length > 0) {
                        [infostr appendFormat:@"<p>%@<br />%@</p>",_cardMeta[@"contextsentence2"],_cardMeta[@"englishsentence2"]];
                    }
                }
            break;
        }
        case DeckTypeKanji: {
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",_cardMeta[@"english"]];
            if (((NSString *)_cardMeta[@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",_cardMeta[@"altmeaning"]];
            }
            int readingtype = ((NSNumber *)_cardMeta[@"readingtype"]).intValue;
            [infostr appendFormat:@"<h1>%@(Primary)</h1><p>%@</p>",readingtype == 0 ? @"On'yomi" : @"Kun'yomi",_cardMeta[@"kanareading"]];
            if (_cardMeta[@"altreading"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"altreading"]).length > 0) {
                    [infostr appendFormat:@"<h1>%@ (Alt.)</h1><p>%@</p>",readingtype == 0 ? @"Kun'yomi" : @"On'yomi",_cardMeta[@"altreading"]];
                }
            }
            if (_cardMeta[@"notes"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",_cardMeta[@"notes"]];
                }
            }
            break;
        }
        case DeckTypeVocab: {
            [infostr appendFormat:@"<h1>Kana Reading</h1><p>%@</p>",_cardMeta[@"kanaWord"]];
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",_cardMeta[@"english"]];
            if (((NSString *)_cardMeta[@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",_cardMeta[@"altmeaning"]];
            }
            if (_cardMeta[@"notes"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",_cardMeta[@"notes"]];
                }
            }
            if (_cardMeta[@"contextsentence1"] != [NSNull null] && _cardMeta[@"englishsentence1"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"contextsentence1"]).length > 0 && ((NSString *)_cardMeta[@"englishsentence1"]).length > 0) {
                    [infostr appendString:@"<h1>Example Sentences</h1>"];
                    [infostr appendFormat:@"<p>%@<br />%@</p>",_cardMeta[@"contextsentence1"],_cardMeta[@"englishsentence1"]];
                }
            }
            if (_cardMeta[@"contextsentence2"] != [NSNull null] && _cardMeta[@"englishsentence2"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"contextsentence2"]).length > 0 && ((NSString *)_cardMeta[@"englishsentence2"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",_cardMeta[@"contextsentence2"],_cardMeta[@"englishsentence2"]];
                }
            }
            if (_cardMeta[@"contextsentence3"] != [NSNull null] && _cardMeta[@"englishsentence3"] != [NSNull null]) {
                if (((NSString *)_cardMeta[@"contextsentence3"]).length > 0 && ((NSString *)_cardMeta[@"englishsentence3"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",_cardMeta[@"contextsentence3"],_cardMeta[@"englishsentence3"]];
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    [infostr appendString:@"<h1>Review Information</h1>"];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterMediumStyle;
    if (((NSNumber *)_cardMeta[@"learned"]).boolValue) {
        [infostr appendFormat:@"<h3>Last Reviewed</h3><p>%@</p>",[df stringFromDate:[NSDate dateWithTimeIntervalSince1970:((NSNumber *)_cardMeta[@"lastreviewed"]).doubleValue]]];
        [infostr appendFormat:@"<h3>Next Review</h3><p>%@</p>",[df stringFromDate:[NSDate dateWithTimeIntervalSince1970:((NSNumber *)_cardMeta[@"nextreviewinterval"]).doubleValue]]];
    }
    [infostr appendFormat:@"<h3>Date Created</h3><p>%@</p>",[df stringFromDate:[NSDate dateWithTimeIntervalSince1970:((NSNumber *)_cardMeta[@"datecreated"]).doubleValue]]];
    
    __weak ItemInfoWindowController* weakSelf = self;
    [_infotextview setTextToHTML:infostr withLoadingText:@"Loading" completion:^(NSAttributedString * _Nonnull astr) {
        weakSelf.infotextview.textColor = NSColor.controlTextColor;
    }];
}

- (IBAction)playvoice:(id)sender {
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc]init];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_cardType == DeckTypeKana ? _cardMeta[@"kanareading"] : _cardMeta[@"reading"]];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
    [synthesizer speakUtterance:utterance];
}

- (IBAction)lookupworddictionary:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"dict://%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookupdictionariesapp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mkdictionaries:///?text=%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookupjisho:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://jisho.org/words?jap=%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookupweblio:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ejje.weblio.jp/content/%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookupalc:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://eow.alc.co.jp/search?q=%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookupgoo:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://dictionary.goo.ne.jp/srch/all/%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}
- (IBAction)lookuptangorin:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tangorin.com/general/%@",[self urlEncodeString:_cardMeta[@"japanese"]]]]];
}

- (NSString *)urlEncodeString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

@end
