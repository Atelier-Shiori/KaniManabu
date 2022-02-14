//
//  ReviewWindowController.m
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import "ReviewWindowController.h"
#import "CardReview.h"
#import "AnswerCheck.h"
#import "ItemInfoWindowController.h"
#import "DeckManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SpeechSynthesis.h"
#import "TKMKanaInput.h"

@interface ReviewWindowController ()
@property (strong) IBOutlet NSButton *scoreitem;
@property (strong) IBOutlet NSButton *correctitem;
@property (strong) IBOutlet NSButton *pendingitem;
@property (strong) IBOutlet NSToolbarItem *iteminfotoolbaritem;
@property (strong) ItemInfoWindowController *iiwc;
@property (strong) NSMutableArray *completeditems;
@property (strong) IBOutlet NSTextField *word;
@property (strong) IBOutlet NSTextField *questionprompt;
@property (strong) IBOutlet NSTextField *answerstatus;
@property (strong) IBOutlet TKMKanaInputTextField *answertextfield;
@property (strong) IBOutlet NSTextField *srslevellabel;
@property (strong) IBOutlet NSButton *answerbtn;
@property int totalitems;
@property int correctcount;
@property int incorrectcount;
@property int questiontype;
@property int currentitem;
@property bool answered;
@property (strong) CardReview* currentcard;
@property bool promptacknowledged;
@property (strong) IBOutlet NSPopover *lasttenpopover;
@property (strong) IBOutlet NSTableView *lasttentb;
@property (strong) IBOutlet NSArrayController *lasttenarraycontroller;
@property (strong) IBOutlet NSTextField *ankiwrongsrsstagelbl;
@property (strong) IBOutlet NSTextField *ankirightstagelbl;
@property (strong) IBOutlet NSButton *ankibtnwrong;
@property (strong) IBOutlet NSButton *ankibtnright;
@property (strong) IBOutlet NSButton *ankishowanswerbtn;
@property (strong) IBOutlet NSPopover *popovervalidationmessage;
@property (strong) IBOutlet NSTextField *validationmessage;
@property (strong) IBOutlet NSToolbarItem *lasttentoolbaritem;
@property (strong) NSString *oldanswerstr;
@property NSRange oldrange;
@property NSRange currentrange;
@property (strong) TKMKanaInput *kanainput;
@property bool useKaniManabuIME;
@end

@implementation ReviewWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"Review"];
    if (!self)
        return nil;
    _reviewqueue = [NSMutableArray new];
    _completeditems = [NSMutableArray new];
    _kanainput = [TKMKanaInput new];
    return self;
}

- (void)awakeFromNib {
    if (@available(macOS 11.0, *)) {
        self.window.titleVisibility = NSWindowTitleHidden;
        self.window.toolbarStyle = NSWindowToolbarStyleUnified;
    }
    else {
        // Fix toolbar icons
        self.window.titleVisibility = NSWindowTitleHidden;
        _scoreitem.image = [NSImage imageNamed:@"thumbsup"];
        _correctitem.image = [NSImage imageNamed:@"check"];
        _pendingitem.image = [NSImage imageNamed:@"inbox"];
        _iteminfotoolbaritem.image = [NSImage imageNamed:@"eye"];
        _lasttentoolbaritem.image = [NSImage imageNamed:@"clock"];
        _answerbtn.image = [NSImage imageNamed:@"arrowright"];
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)startReview:(NSArray *)reviewitems {
    if (_learnmode) {
        // Hide Score and correctitem, not applicable in learning mode.
        _scoreitem.hidden = YES;
        _correctitem.hidden = YES;
    }
    if (_ankimode) {
        // Hide answer text field, buttons will show instead
        _answertextfield.hidden = YES;
        _answertextfield.enabled = NO;
        _answerbtn.hidden = YES;
    }
    _useKaniManabuIME = [NSUserDefaults.standardUserDefaults boolForKey:@"usekanimanabuime"];
    [_reviewqueue addObjectsFromArray:reviewitems];
    _pendingitem.title = @(_reviewqueue.count).stringValue;
    [self nextQuestion];
}

- (IBAction)viewitem:(id)sender {
    if (!_iiwc) {
        _iiwc = [ItemInfoWindowController new];
    }
    [_iiwc.window makeKeyAndOrderFront:self];
    [_iiwc setDictionary:[DeckManager.sharedInstance getCardWithCardUUID:[_currentcard.card valueForKey:@"carduuid"] withType:_currentcard.cardtype] withWindowType:ParentWindowTypeReview];
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
    [alert setMessageText:_learnmode ? NSLocalizedString(@"Do you want to end this learning session?",nil) :  NSLocalizedString(@"Do you want to end this review session?",nil)];
    [alert setInformativeText:_learnmode ? NSLocalizedString(@"Your progress won't be saved until you reviewed the new items.",nil) : NSLocalizedString(@"Any review items not fully reviewed will remain in the review queue.",nil)];
    // Set Message type to Warning
    alert.alertStyle = NSAlertStyleInformational;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode== NSAlertFirstButtonReturn) {
            self.promptacknowledged = YES;
            // Suspend items that are still in the queue
            for (CardReview *card in self.reviewqueue) {
                [card suspendReview];
            }
            [self showReviewComplete];
        }
    }];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    if (_questiontype == CardReviewTypeReading && _useKaniManabuIME) {
        if ([obj.object isEqual:_answertextfield]) {
                _currentrange = NSMakeRange(_answertextfield.currentEditor.selectedRange.location, 0);
                _oldrange = NSMakeRange(_answertextfield.StartLocation, 0);
                if (_oldrange.location > _currentrange.location) {
                    _oldrange = _currentrange;
                _answertextfield.StartLocation = _oldrange.location;
                }
                bool usecurrentlocation = false;
                if (_currentrange.location > 1) {
                    NSString *astring = [_answertextfield.stringValue substringWithRange:NSMakeRange(_currentrange.location-1, 1)];
                    NSString *bstring = [_answertextfield.stringValue substringWithRange:NSMakeRange(_currentrange.location-2, 1)];
                    if ([astring isEqualToString:bstring] && [astring caseInsensitiveCompare:@"n"] != NSOrderedSame && [bstring caseInsensitiveCompare:@"n"] != NSOrderedSame) {
                        usecurrentlocation = true;
                    }
                }
                @try{
                    NSRange substr = NSMakeRange(usecurrentlocation ? _currentrange.location-1 : _oldrange.location, usecurrentlocation ? 1 : _currentrange.location-_oldrange.location);            NSString *replacementstr = [_answertextfield.stringValue substringWithRange:substr];
                    NSDictionary *proposed = [_kanainput checkString:_answertextfield.stringValue withReplacementString:replacementstr withOldRange:_oldrange withCurrentRange:_currentrange useCurrentRange:usecurrentlocation];
                    NSString *newstring = proposed[@"string"];
                    if (![newstring isEqualToString:_answertextfield.stringValue]) {
                        _answertextfield.stringValue = newstring;
                        _answertextfield.currentEditor.selectedRange = NSMakeRange(((NSNumber *)proposed[@"newposition"]).intValue, 0);
                        _currentrange = NSMakeRange(_answertextfield.currentEditor.selectedRange.location, 0);
                        _answertextfield.StartLocation = usecurrentlocation ? _answertextfield.currentEditor.selectedRange.location - 1 : _answertextfield.currentEditor.selectedRange.location;
                        _oldrange = NSMakeRange(_answertextfield.StartLocation, 0);
                    }
                }
                @catch (NSException *ex){}
                _oldanswerstr = _answertextfield.stringValue;
            }
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (((NSNumber *)[notification.userInfo objectForKey:@"NSTextMovement"]).intValue == NSReturnTextMovement) {
        [self checkAnswer];
    }
}

- (IBAction)checkanswer:(id)sender {
    [self checkAnswer];
}

- (void)checkAnswer {
    if (!_answered) {
        if (_answertextfield.stringValue.length == 0) {
            [self shake:_answertextfield];
            NSBeep();
        }
        else {
            [self performCheckAnswer];
        }
    }
    else {
        [self setTextFieldAnswerBackground:2];
        [self nextQuestion];
    }
}

- (void)performCheckAnswer {
    _answerstatus.stringValue = @"";
    [_popovervalidationmessage close];
    NSString * correctAnswer;
    switch (_currentcard.cardtype) {
        case CardTypeKana: {
            // Kana is meaning only.
            correctAnswer = [_currentcard.card valueForKey:@"english"];
            break;
        }
        case CardTypeVocab: {
            if (_questiontype == CardReviewTypeMeaning) {
                correctAnswer = [_currentcard.card valueForKey:@"english"];
            }
            else {
                correctAnswer = [_currentcard.card valueForKey:@"kanaWord"];
            }
            break;
        }
        case CardTypeKanji: {
            if (_questiontype == CardReviewTypeMeaning) {
                correctAnswer = [_currentcard.card valueForKey:@"english"];
            }
            else {
                correctAnswer = [_currentcard.card valueForKey:@"kanareading"];
            }
            break;
        }
    }
    if (_questiontype == CardReviewTypeMeaning) {
        int answerstate = [AnswerCheck checkMeaning:_answertextfield.stringValue withCard:_currentcard.card];
        switch (answerstate) {
            case AnswerStatePrecise: {
                [self setTextFieldAnswerBackground:1];
                break;
            }
            case AnswerStateInprecise: {
                [self setTextFieldAnswerBackground:1];
                _answerstatus.stringValue = @"Your answer was a bit off. Check your answer with the item info to see if your answer was correct";
                break;
            }
            case AnswerStateVerbNoTo: {
                [self showvalidationmessage:[NSString stringWithFormat:@"Almost, but this is a verb. Enter \"to %@\".", _answertextfield.stringValue]];
                return;
            }
            case AnswerStateInvalidCharacters: {
                NSBeep();
                [self shake:_answertextfield];
                return;
            }
            case AnswerStateJapaneseReadingAnswer: {
                [self showvalidationmessage:@"You entered the Japanese reading, we want the meaning."];
                return;
            }
            case AnswerStateIncorrect: {
                [self setTextFieldAnswerBackground:0];
                _answerstatus.stringValue = @"Need Help? Click the Item Info to view the correct answer.";
                _currentcard.currentreviewmeaningincorrect = true;
                _answered = true;
                _iteminfotoolbaritem.enabled = true;
                [_currentcard setIncorrect:CardReviewTypeMeaning];
                return;
            }
        }
        _currentcard.reviewedmeaning = true;
        _answered = true;
        [_currentcard setCorrect:CardReviewTypeMeaning];
        if (_currentcard.cardtype == CardTypeKana) {
            // Say Vocab reading if user enabled option
            if ([NSUserDefaults.standardUserDefaults boolForKey:@"SayKanaReadingAnswer"]) {
                [self sayAnswer:[_currentcard.card valueForKey:@"kanareading"]];
            }
        }
    }
    else if (_questiontype == CardReviewTypeReading) {
        int answerstate = _currentcard.cardtype == CardTypeKanji ? [AnswerCheck checkKanjiReading:_answertextfield.stringValue withCard:_currentcard.card] : [AnswerCheck checkVocabReading:_answertextfield.stringValue withCard:_currentcard.card];
        switch (answerstate) {
            case AnswerStatePrecise: {
                [self setTextFieldAnswerBackground:1];
                break;
            }
            case AnswerStateOtherKanjiReading: {
                [self showvalidationmessage:[NSString stringWithFormat:@"We want the %@ of this Kanji.", ((NSNumber *)[_currentcard.card valueForKey:@"readingtype"]).intValue == 0 ? @"On'yomi" : @"Kun'yomi"]];
                NSBeep();
                [self shake:_answertextfield];
                return;
            }
            case AnswerStateInvalidCharacters: {
                NSBeep();
                [self shake:_answertextfield];
                [self showvalidationmessage:@"Make sure you are typing your answers in Hiragana or Katakana only."];
                return;
            }
            case AnswerStateIncorrect: {
                [self setTextFieldAnswerBackground:0];
                _answerstatus.stringValue = @"Need Help? Click the Item Info to view the correct answer.";
                _currentcard.currentreviewmeaningincorrect = true;
                _answered = true;
                _iteminfotoolbaritem.enabled = true;
                [_currentcard setIncorrect:CardReviewTypeReading];
                return;
            }
        }
        if (_currentcard.cardtype == CardTypeVocab) {
            // Say Vocab reading if user enabled option
            if ([NSUserDefaults.standardUserDefaults boolForKey:@"SayKanaReadingAnswer"]) {
                [self sayAnswer:[_currentcard.card valueForKey:@"reading"]];
            }
        }
        _currentcard.reviewedreading = true;
        _answered = true;
        _iteminfotoolbaritem.enabled = true;
        [_currentcard setCorrect:CardReviewTypeReading];
    }
    if (_currentcard.reviewedmeaning && _currentcard.reviewedreading) {
        if (!_learnmode) {
            // Show New SRS Level
            [self showNewSRSStage:YES];
        }
        _iteminfotoolbaritem.enabled = true;
    }
}

- (void)reviewComplete {
    [_currentcard finishReview];
    if (!_currentcard.currentreviewmeaningincorrect && !_currentcard.currentreviewreadingincorrect) {
        _correctcount++;
    }
    else {
        _incorrectcount++;
    }
    [_completeditems addObject:_currentcard];
    [_reviewqueue removeObject:_currentcard];
    [self reloadFinishList];
}

- (void)calculatescores {
    _correctitem.title = @(_correctcount).stringValue;
    _scoreitem.title = [NSString stringWithFormat:@"%.0f%%",@(((double)_correctcount/((double)_correctcount+(double)_incorrectcount))*100).floatValue];
    _pendingitem.title = @(_reviewqueue.count).stringValue;
}

- (void)nextQuestion {
    [NSNotificationCenter.defaultCenter postNotificationName:@"ReviewAdvanced" object:nil];
    _iteminfotoolbaritem.enabled = false;
    _answered = false;
    if (!_ankimode) {
        _answerstatus.stringValue = @"";
        [self showNewSRSStage:NO];
    }
    else {
        _ankishowanswerbtn.hidden = NO;
        _ankibtnright.hidden = YES;
        _ankibtnwrong.hidden = YES;
        _ankirightstagelbl.hidden = YES;
        _ankiwrongsrsstagelbl.hidden = YES;
    }
    if (_currentcard) {
        // Check if both questions are answered. If so, mark as complete
        if (_currentcard.reviewedmeaning && _currentcard.reviewedreading) {
            [self reviewComplete];
            [self calculatescores];
            if (_reviewqueue.count == 0) {
                // Review complete
                [self showReviewComplete];
                return;
            }
        }
    }
    if (_reviewqueue.count > 0) {
        // Pick a random index number with the max being the number of cards in queue
        int ranindex = arc4random_uniform((int)_reviewqueue.count);
        _currentcard = _reviewqueue[ranindex];
        // Determine whether or not to review meaning or reading first
        if (!_currentcard.reviewedmeaning && !_currentcard.reviewedreading) {
            _questiontype = arc4random_uniform(2);
        }
        else if (!_currentcard.reviewedmeaning && _currentcard.reviewedreading) {
            _questiontype = 0;
        }
        else {
            _questiontype = 1;
        }
        [self setUpQuestion];
    }
    else {
        [self showReviewComplete];
    }
}

- (void)showReviewComplete {
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"OK"];
    if (!_learnmode) {
        [alert setMessageText:@"Review Completed!"];
        alert.informativeText = [NSString stringWithFormat:@"Your score is %@ with %i correct and %i incorrect.", _scoreitem.title, _correctcount, _incorrectcount];
    }
    else {
        [alert setMessageText:@"Lesson Completed!"];
        alert.informativeText = [NSString stringWithFormat:@"You have learned %lu %@ and they are added to the review queue.", _completeditems.count, _completeditems.count == 1 ? @"card" : @"cards"];
    }
    alert.alertStyle = NSAlertStyleInformational;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        self.promptacknowledged = YES;
        [NSNotificationCenter.defaultCenter postNotificationName:@"ReviewEnded" object:nil];
        [self.window close];
        }];
}

- (void)setUpQuestion {
    _word.stringValue = [_currentcard.card valueForKey:@"japanese"];
    switch (_questiontype) {
        case CardReviewTypeMeaning: {
            switch (_currentcard.cardtype) {
                case CardTypeKana: {
                    _questionprompt.stringValue = @"Kana Meaning";
                    break;
                }
                case CardTypeVocab: {
                    _questionprompt.stringValue = @"Vocabulary Meaning";
                    break;
                }
                case CardTypeKanji: {
                    _questionprompt.stringValue = @"Kanji Meaning";
                    break;
                }
            }
            _answertextfield.placeholderString = @"Enter Meaning";
            break;
        }
        case CardReviewTypeReading: {
            switch (_currentcard.cardtype) {
                case CardTypeVocab: {
                    _questionprompt.stringValue = @"Vocabulary Reading";
                    break;
                }
                case CardTypeKanji: {
                    _questionprompt.stringValue = @"Kanji Reading";
                    break;
                }
            }
            _answertextfield.placeholderString = @"答えを入力してください";
            _oldanswerstr = @"";
            _oldrange = NSMakeRange(0, 0);
            _answertextfield.StartLocation = 0;
        }
    }
}
- (IBAction)showanswer:(id)sender {
    [self performshowAnswer];
}

- (void)performshowAnswer {
    switch (_questiontype) {
        case CardReviewTypeMeaning: {
            _questionprompt.stringValue = [_currentcard.card valueForKey:@"english"];
            break;
        }
        case CardReviewTypeReading: {
            switch (_currentcard.cardtype) {
                case CardTypeVocab: {
                    if (_currentcard.cardtype == CardTypeVocab) {
                        // Say Vocab reading if user enabled option
                        if ([NSUserDefaults.standardUserDefaults boolForKey:@"SayKanaReadingAnswer"]) {
                            [self sayAnswer:[_currentcard.card valueForKey:@"reading"]];
                        }
                    }
                    _questionprompt.stringValue = [_currentcard.card valueForKey:@"kanaWord"];
                    break;
                }
                case CardTypeKanji: {
                    _questionprompt.stringValue = [_currentcard.card valueForKey:@"reading"];
                    break;
                }
            }
            break;
        }
    }
    _ankishowanswerbtn.hidden = YES;
    _ankibtnright.hidden = NO;
    _ankibtnwrong.hidden = NO;
    _ankirightstagelbl.hidden = NO;
    _ankiwrongsrsstagelbl.hidden = NO;
    _ankirightstagelbl.stringValue = [SRScheduler getSRSStageNameWithCurrentSRSStage:_currentcard.proposedSRSStage+1];
    _ankiwrongsrsstagelbl.stringValue = [SRScheduler getSRSStageNameWithCurrentSRSStage:_currentcard.proposedSRSStage-1 <= 0 ? 1 : _currentcard.proposedSRSStage-1];
    _answered = true;
    _iteminfotoolbaritem.enabled = true;
}
- (IBAction)ankianswerwrong:(id)sender {
    switch (_questiontype) {
        case CardReviewTypeMeaning: {
            [_currentcard setIncorrect:CardReviewTypeMeaning];
            _currentcard.currentreviewmeaningincorrect = true;
            break;
        }
        case CardReviewTypeReading: {
            [_currentcard setIncorrect:CardReviewTypeReading];
            _currentcard.currentreviewreadingincorrect = true;
            break;
        }
    }
    [self nextQuestion];
}
- (IBAction)ankianswerright:(id)sender {
    switch (_questiontype) {
        case CardReviewTypeMeaning: {
            [_currentcard setCorrect:CardReviewTypeMeaning];
            _currentcard.currentreviewmeaningincorrect = false;
            break;
        }
        case CardReviewTypeReading: {
            [_currentcard setCorrect:CardReviewTypeReading];
            _currentcard.currentreviewreadingincorrect = false;
            break;
        }
    }
    [self nextQuestion];
}

- (IBAction)showlast10:(id)sender {
    [_lasttenpopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

- (void)reloadFinishList {
    NSMutableArray *a = [_lasttenarraycontroller mutableArrayValueForKey:@"content"];
    [a removeAllObjects];
    for (long i = _completeditems.count -1; i >=0; i--) {
        [_lasttenarraycontroller addObject:@{@"japanese" : [((CardReview *)_completeditems[i]).card valueForKey:@"japanese"]}];
        if (((NSMutableArray *)[_lasttenarraycontroller mutableArrayValueForKey:@"content"]).count == 10) {
            break;
        }
    }
    [_lasttentb reloadData];
}


#pragma mark helpers

- (void)setTextFieldAnswerBackground:(int)state {
    switch (state) {
        case 0: {
            //Incorrect
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                [NSAnimationContext beginGrouping];
                context.duration = 3;
                _answertextfield.animator.backgroundColor = NSColor.systemRedColor;
                _answertextfield.animator.textColor = NSColor.whiteColor;
                [NSAnimationContext endGrouping];
                [context setCompletionHandler:^{
                    
                }];
            }];
            _answertextfield.editable = NO;
            _answertextfield.currentEditor.selectedRange = NSMakeRange(0, 0);
            break;
            }
        case 1: {
            //Correct
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                [NSAnimationContext beginGrouping];
                context.duration = 3;
                _answertextfield.animator.backgroundColor = NSColor.systemGreenColor;
                _answertextfield.animator.textColor = NSColor.whiteColor;
                [NSAnimationContext endGrouping];
                [context setCompletionHandler:^{
                    
                }];
            }];
            _answertextfield.editable = NO;
            _answertextfield.currentEditor.selectedRange = NSMakeRange(0, 0);
            break;
            }
        case 2:{
            // Reset
            _answertextfield.backgroundColor = NSColor.textBackgroundColor;
            _answertextfield.textColor = NSColor.textColor;
            _answertextfield.stringValue = @"";
            _answertextfield.editable = YES;
            _answerbtn.keyEquivalent = @"";
            break;
        }
    }
}

- (void)showNewSRSStage:(bool)show {
    if (show) {
        _srslevellabel.hidden = NO;
        _srslevellabel.drawsBackground = YES;
        _srslevellabel.wantsLayer = YES;
        _srslevellabel.alphaValue = 0;
        int oriygorigin = _srslevellabel.frame.origin.y;
        [_srslevellabel setFrame:CGRectMake(_srslevellabel.frame.origin.x, oriygorigin-40, _srslevellabel.frame.size.width, _srslevellabel.frame.size.height)];
        if (_currentcard.currentreviewmeaningincorrect || _currentcard.currentreviewreadingincorrect) {
            _srslevellabel.backgroundColor = NSColor.systemRedColor;
            _srslevellabel.textColor = NSColor.whiteColor;
        }
        else {
            _srslevellabel.backgroundColor = NSColor.systemGreenColor;
            _srslevellabel.textColor = NSColor.whiteColor;
        }
        _srslevellabel.stringValue = [SRScheduler getSRSStageNameWithCurrentSRSStage:_currentcard.proposedSRSStage];
        //Fade in
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            [NSAnimationContext beginGrouping];
            context.duration = 1;
            _srslevellabel.animator.alphaValue = .25;
            _srslevellabel.animator.frame = CGRectMake(_srslevellabel.frame.origin.x, oriygorigin-40, _srslevellabel.frame.size.width, _srslevellabel.frame.size.height);
            [NSAnimationContext endGrouping];
            [context setCompletionHandler:^{
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                    [NSAnimationContext beginGrouping];
                    context.duration = 1;
                    self.srslevellabel.animator.alphaValue = .7;
                    self.srslevellabel.animator.frame = CGRectMake(self.srslevellabel.frame.origin.x, oriygorigin-20, self.srslevellabel.frame.size.width, self.srslevellabel.frame.size.height);
                    [NSAnimationContext endGrouping];
                    [context setCompletionHandler:^{
                        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                            [NSAnimationContext beginGrouping];
                            context.duration = 1;
                            self.srslevellabel.animator.alphaValue = 1;
                            self.srslevellabel.animator.frame = CGRectMake(self.srslevellabel.frame.origin.x, oriygorigin, self.srslevellabel.frame.size.width, self.srslevellabel.frame.size.height);
                            [NSAnimationContext endGrouping];
                            [context setCompletionHandler:^{
                                
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }
    else {
        _srslevellabel.hidden = YES;
    }
}

- (void)shake:(NSTextField *)textfield {
    @try {
    NSRect textFieldFrame = [textfield frame];

    CGFloat centerX = textFieldFrame.origin.x;
    CGFloat centerY = textFieldFrame.origin.y;

    NSPoint origin = NSMakePoint(centerX, centerY);
    NSPoint one = NSMakePoint(centerX-5, centerY);
    NSPoint two = NSMakePoint(centerX+5, centerY);


    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{

        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{


            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setCompletionHandler:^{

                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setCompletionHandler:^{

                    [[NSAnimationContext currentContext] setDuration:0.0175];
                    [[NSAnimationContext currentContext] setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
                    [[textfield animator] setFrameOrigin:origin];

                }];

                [[NSAnimationContext currentContext] setDuration:0.0175];
                [[NSAnimationContext currentContext] setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
                [[textfield animator] setFrameOrigin:two];
                [NSAnimationContext endGrouping];

            }];

            [[NSAnimationContext currentContext] setDuration:0.0175];
            [[NSAnimationContext currentContext] setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
            [[textfield animator] setFrameOrigin:one];
            [NSAnimationContext endGrouping];
        }];

        [[NSAnimationContext currentContext] setDuration:0.0175];
        [[NSAnimationContext currentContext] setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
        [[textfield animator] setFrameOrigin:two];
        [NSAnimationContext endGrouping];

    }];

    [[NSAnimationContext currentContext] setDuration:0.0175];
    [[NSAnimationContext currentContext] setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
    [[textfield animator] setFrameOrigin:one];
    [NSAnimationContext endGrouping];
    }
    @catch (NSException *ex) {
        
    }
}

- (void)sayAnswer:(NSString *)answer {
    [SpeechSynthesis.sharedInstance sayText:answer];
}

- (void)showvalidationmessage:(NSString *)text {
    [_validationmessage setFrameSize:NSMakeSize(600, 20)];
    _validationmessage.stringValue = text;
    [_popovervalidationmessage showRelativeToRect:[_answertextfield bounds] ofView:_answertextfield preferredEdge:NSMaxYEdge];
}
@end
