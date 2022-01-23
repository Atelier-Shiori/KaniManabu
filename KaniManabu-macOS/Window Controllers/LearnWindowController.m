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

@interface LearnWindowController ()
@property (strong) IBOutlet NSTextField *wordlabel;
@property (strong) IBOutlet NSTextView *infotextview;
@property (strong) IBOutlet NSToolbarItem *playvoicetoolbaritem;
@property (strong) IBOutlet NSProgressIndicator *progress;
@property (strong) IBOutlet NSToolbarItem *backtoolbaritem;
@property (strong) CardReview *currentcard;
@property int currentitem;
@property bool promptacknowledged;
@end

@implementation LearnWindowController
- (instancetype)init {
    self = [super initWithWindowNibName:@"Learn"];
    if (!self)
        return nil;
    return self;
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
            [infostr appendFormat:@"<h1>English Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"english"]];
            if (((NSString *)[_currentcard.card valueForKey:@"altmeaning"]).length > 0) {
                [infostr appendFormat:@"<h1>Alt Meaning</h1><p>%@</p>",[_currentcard.card valueForKey:@"altmeaning"]];
            }
            int readingtype = ((NSNumber *)[_currentcard.card valueForKey:@"readingtype"]).intValue;
            [infostr appendFormat:@"<h1>%@(Primary)</h1><p>%@</p>",readingtype == 0 ? @"On'yomi" : @"Kun'yomi",[_currentcard.card valueForKey:@"kanareading"]];
            if ([_currentcard.card valueForKey:@"altreading"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"altreading"]).length > 0) {
                    [infostr appendFormat:@"<h1>%@ (Alt.)</h1><p>%@</p>",readingtype == 0 ? @"Kun'yomi" : @"On'yomi",[_currentcard.card valueForKey:@"altreading"]];
                }
            }
            if ([_currentcard.card valueForKey:@"notes"]) {
                if (((NSString *)[_currentcard.card valueForKey:@"notes"]).length > 0) {
                    [infostr appendFormat:@"<h1>Notes</h1><p>%@</p>",[_currentcard.card valueForKey:@"notes"]];
                }
            }
            break;
        }
        case DeckTypeVocab: {
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
    __weak LearnWindowController* weakSelf = self;
    [_infotextview setTextToHTML:infostr withLoadingText:@"Loading" completion:^(NSAttributedString * _Nonnull astr) {
        weakSelf.infotextview.textColor = NSColor.controlTextColor;
        // Say Vocab reading if user enabled option
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"SayKanaReadingAnswer"]) {
            [self playvoice:nil];
        }
    }];
}

- (IBAction)playvoice:(id)sender {
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc]init];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_currentcard.cardtype == DeckTypeKana ? [_currentcard.card valueForKey:@"kanareading"] : [_currentcard.card valueForKey:@"reading"]];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
    [synthesizer speakUtterance:utterance];
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
