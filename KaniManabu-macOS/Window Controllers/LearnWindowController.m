//
//  LearnWindowController.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import "LearnWindowController.h"
#import "DeckManager.h"
#import "CardReview.h"
#import "NSString+HTMLtoNSAttributedString.h"
#import "NSTextView+SetHTMLAttributedText.h"
#import <AVFoundation/AVFoundation.h>
#import "WaniKani.h"

@interface LearnWindowController ()
@property (strong) IBOutlet NSTextField *wordlabel;
@property (strong) IBOutlet NSTextView *infotextview;
@property (strong) IBOutlet NSToolbarItem *playvoicetoolbaritem;
@property (strong) IBOutlet NSProgressIndicator *progress;
@property (strong) IBOutlet NSToolbarItem *backtoolbaritem;
@property (strong) IBOutlet NSToolbarItem *lookupindictionarytoolbaritem;
@property (strong) IBOutlet NSToolbarItem *otherresourcestoolbaritem;
@property (strong) CardReview *currentcard;
@property int currentitem;
@property bool promptacknowledged;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong) IBOutlet NSTextField *furiganas;
@property (strong) AVSpeechSynthesizer *synthesizer;
@end

@implementation LearnWindowController
- (instancetype)init {
    self = [super initWithWindowNibName:@"Learn"];
    if (!self)
        return nil;
    return self;
}

- (void)awakeFromNib {
    if (@available(macOS 11.0, *)) {
        self.window.titleVisibility = NSWindowTitleHidden;
        self.window.toolbarStyle = NSWindowToolbarStyleUnified;
    }
    else {
        self.window.titleVisibility = NSWindowTitleHidden;
        _playvoicetoolbaritem.image = [NSImage imageNamed:@"play"];
        _lookupindictionarytoolbaritem.image = [NSImage imageNamed:@"bookshelf"];
        _otherresourcestoolbaritem.image = [NSImage imageNamed:@"safari"];;
    }
}


- (void)loadStudyItemsForDeckUUID:(NSUUID *)uuid withType:(int)deckType {
    NSArray *learnitems = [DeckManager.sharedInstance setandretrieveLearnItemsForDeckUUID:uuid withType:deckType];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSManagedObject *card in learnitems) {
        CardReview *creview = [[CardReview alloc] initWithCard:card withCardType:deckType];
        creview.learningmode = true;
        creview.cardtype = deckType;
        creview.card = card;
        [tmparray addObject:creview];
    }
    _studyitems = tmparray;
    _progress.maxValue = _studyitems.count;
    _currentitem = 0;
    _progress.doubleValue = _currentitem+1;
    _backtoolbaritem.enabled = NO;
    [self populateValues];
}

- (IBAction)goBack:(id)sender {
    _currentitem--;
    _progress.doubleValue = _currentitem+1;
    if (_currentitem == 0) {
        _backtoolbaritem.enabled = NO;
    }
    [self populateValues];
}
- (IBAction)goForward:(id)sender {
    if (_currentitem < _studyitems.count-1) {
        _currentitem++;
        _progress.doubleValue = _currentitem+1;
        if (_currentitem > 0) {
            _backtoolbaritem.enabled = YES;
        }
        [self populateValues];
    }
    else {
        [self quizprompt];
    }
}

- (void)quizprompt {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Do the Lesson Review Quiz?";
    alert.informativeText = @"You have viewed all the cards in the lesson queue. Do you want to take the quiz?";
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"StartLearningReviewQuiz" object:nil];
            self.promptacknowledged = YES;
            [self.window close];
        }
    }];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    _privateQueue = dispatch_queue_create("moe.ateliershiori.KaniManabu.Learn", DISPATCH_QUEUE_CONCURRENT);
    _synthesizer = [[AVSpeechSynthesizer alloc]init];
}

- (BOOL)windowShouldClose:(id)sender {
    // Show prompt to end learning session first
    if (_promptacknowledged) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"LearnEnded" object:nil];
        return YES;
    }
    [self showCloseWindowPrompt];
    return NO;
}

- (void)showCloseWindowPrompt {
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert setMessageText:NSLocalizedString(@"Do you want to end this learning session?",nil)];
    [alert setInformativeText:NSLocalizedString(@"Your progress won't be saved until you reviewed the new items.",nil)];
    // Set Message type to Warning
    alert.alertStyle = NSAlertStyleInformational;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode== NSAlertFirstButtonReturn) {
            self.promptacknowledged = YES;
            [NSNotificationCenter.defaultCenter postNotificationName:@"LearnEnded" object:nil];
            [self.window close];
        }
    }];
}

- (void)populateValues {
    _currentcard = _studyitems[_currentitem];
    _wordlabel.stringValue = [_currentcard.card valueForKey:@"japanese"];
    if (_currentcard.cardtype == DeckTypeKanji) {
        _playvoicetoolbaritem.enabled = false;
    }
    else {
        _playvoicetoolbaritem.enabled = true;
    }
    [self populateInfoSection];
}

- (void)populateInfoSection {
    NSMutableString *infostr = [NSMutableString new];
    switch (_currentcard.cardtype) {
        case DeckTypeKana: {
            _furiganas.stringValue = @"";
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"english"]];
            if (((NSString *)[_currentcard.card valueForKey:@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"altmeaning"]];
            }
            if ([_currentcard.card valueForKey:@"notes"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",[_currentcard.card valueForKey:@"notes"]];
                }
            }
            if ([_currentcard.card valueForKey:@"contextsentence1"] && [_currentcard.card valueForKey:@"englishsentence1"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"contextsentence1"]).length > 0 && ((NSString *)[_currentcard.card valueForKey:@"englishsentence1"]).length > 0) {
                    [infostr appendString:@"<h1>Example Sentences</h1>"];
                    [infostr appendFormat:@"<p>%@<br />%@</p>",[_currentcard.card valueForKey:@"contextsentence1"],[_currentcard.card valueForKey:@"englishsentence1"]];
                }
            }
            if ([_currentcard.card valueForKey:@"contextsentence2"] && [_currentcard.card valueForKey:@"englishsentence2"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"contextsentence2"]).length > 0 && ((NSString *)[_currentcard.card valueForKey:@"englishsentence2"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",[_currentcard.card valueForKey:@"contextsentence2"],[_currentcard.card valueForKey:@"englishsentence2"]];
                }
            }
            break;
        }
        case DeckTypeKanji: {
            _furiganas.stringValue = @"";
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"english"]];
            if (((NSString *)[_currentcard.card valueForKey:@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"altmeaning"]];
            }
            int readingtype = ((NSNumber *)[_currentcard.card valueForKey:@"readingtype"]).intValue;
            [infostr appendFormat:readingtype == 0 ? @"<h1>On'yomi</h1><p><b>%@</b></p>" : @"<h1>On'yomi</h1><p>%@</p>", [_currentcard.card valueForKey:@"kanareading"]];
            [infostr appendFormat:readingtype == 0 ? @"<h1>Kun'yomi</h1><p>%@</p>" : @"<h1>Kun'yomi</h1><p><b>%@</b></p>", [_currentcard.card valueForKey:@"altreading"] ? [_currentcard.card valueForKey:@"altreading"] : @""];
            if ([_currentcard.card valueForKey:@"notes"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",[_currentcard.card valueForKey:@"notes"]];
                }
            }
            break;
        }
        case DeckTypeVocab: {
            _furiganas.stringValue = [_currentcard.card valueForKey:@"kanaWord"];
            [infostr appendFormat:@"<h2>Japanese Kana</h2><p>%@</p>",[_currentcard.card valueForKey:@"kanaWord"]];
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"english"]];
            if (((NSString *)[_currentcard.card valueForKey:@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"altmeaning"]];
            }
            if ([_currentcard.card valueForKey:@"notes"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",[_currentcard.card valueForKey:@"notes"]];
                }
            }
            if ([_currentcard.card valueForKey:@"contextsentence1"] && [_currentcard.card valueForKey:@"englishsentence1"]) {
                [infostr appendString:@"<h1>Example Sentences</h1>"];
                if (((NSString *)[_currentcard.card valueForKey:@"contextsentence1"]).length > 0 && ((NSString *)[_currentcard.card valueForKey:@"englishsentence1"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",[_currentcard.card valueForKey:@"contextsentence1"],[_currentcard.card valueForKey:@"englishsentence1"]];
                }
            }
            if ([_currentcard.card valueForKey:@"contextsentence2"] && [_currentcard.card valueForKey:@"englishsentence2"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"contextsentence2"]).length > 0 && ((NSString *)[_currentcard.card valueForKey:@"englishsentence2"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",[_currentcard.card valueForKey:@"contextsentence2"],[_currentcard.card valueForKey:@"englishsentence2"]];
                }
            }
            if ([_currentcard.card valueForKey:@"contextsentence3"] && [_currentcard.card valueForKey:@"englishsentence3"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"contextsentence3"]).length > 0 && ((NSString *)[_currentcard.card valueForKey:@"englishsentence3"]).length > 0) {
                    [infostr appendFormat:@"<p>%@<br />%@</p>",[_currentcard.card valueForKey:@"contextsentence3"],[_currentcard.card valueForKey:@"englishsentence3"]];
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    if ([WaniKani.sharedInstance getToken] && _currentcard.cardtype == DeckTypeVocab) {
        _infotextview.string = @"Loading";
        dispatch_async(self.privateQueue, ^{
            [WaniKani.sharedInstance analyzeWord:[self.currentcard.card valueForKey:@"japanese"] completionHandler:^(NSArray * _Nonnull data) {
                if (data.count > 0) {
                    [infostr appendString:@"<h1>Kanji Breakdown</h1>"];
                    for (NSDictionary *kanji in data) {
                        [infostr appendFormat:@"<h2>%@ - %@</h2>", kanji[@"data"][@"slug"], kanji[@"data"][@"meanings"][0][@"meaning"]];
                        NSMutableArray *othermeanings = [NSMutableArray new];
                        for (NSDictionary *omeanings in kanji[@"data"][@"meanings"]) {
                            if (!((NSNumber *)omeanings[@"primary"]).boolValue && ((NSNumber *)omeanings[@"accepted_answer"]).boolValue) {
                                [othermeanings addObject:omeanings[@"meaning"]];
                            }
                        }
                        if (othermeanings.count > 0 ) {
                            [infostr appendFormat:@"<h3>Other Meanings</h3><p>%@</p>", [othermeanings componentsJoinedByString:@", "]];
                        }
                        [infostr appendFormat:@"<h3>Level</h3><p>%@</p>",kanji[@"data"][@"level"]];
                        [infostr appendFormat:@"<h3>Characters</h3><p>%@</p>",kanji[@"data"][@"characters"]];
                        for (NSDictionary *readings in kanji[@"data"][@"readings"]) {
                            [infostr appendFormat:((NSNumber *)readings[@"primary"]).boolValue ? @"<h3>%@</h3><p><b>%@</b></p>" : @"<h3>%@</h3><p>%@</p>", ((NSString *)readings[@"type"]).capitalizedString, readings[@"reading"]];
                        }
                        [infostr appendFormat:@"<h3>Reading Mnemonic</h3><p>%@</p>",kanji[@"data"][@"reading_mnemonic"]];
                        [infostr appendFormat:@"<h3>Reading Hint</h3><p>%@</p>",kanji[@"data"][@"reading_hint"]];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadInfo:infostr];
                });
            }];
        });
    }
    else {
        [self loadInfo:infostr];
    }

}

- (void)loadInfo:(NSMutableString *)infostr {
    __weak LearnWindowController* weakSelf = self;
    [_infotextview setTextToHTML:infostr withLoadingText:@"Loading" completion:^(NSAttributedString * _Nonnull astr) {
        weakSelf.infotextview.textColor = NSColor.controlTextColor;
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"SayKanaReadingAnswer"] && (weakSelf.currentcard.cardtype == CardTypeKana || weakSelf.currentcard.cardtype == CardTypeVocab )) {
            [weakSelf playvoice:nil];
        }
    }];
}


- (IBAction)playvoice:(id)sender {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_currentcard.cardtype == DeckTypeKana ? [_currentcard.card valueForKey:@"kanareading"] : [_currentcard.card valueForKey:@"reading"]];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier: [NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] == 0 ? @"com.apple.speech.synthesis.voice.kyoko.premium" : @"com.apple.speech.synthesis.voice.otoya.premium"];
    [_synthesizer speakUtterance:utterance];
}

- (IBAction)lookupworddictionary:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"dict://%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookupdictionariesapp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mkdictionaries:///?text=%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookupjisho:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://jisho.org/words?jap=%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookupweblio:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ejje.weblio.jp/content/%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookupalc:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://eow.alc.co.jp/search?q=%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookupgoo:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://dictionary.goo.ne.jp/srch/all/%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}
- (IBAction)lookuptangorin:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tangorin.com/general/%@",[self urlEncodeString:[_currentcard.card valueForKey:@"japanese"]]]]];
}

- (NSString *)urlEncodeString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

@end
