//
//  DeckStatsWindow.m
//  KaniManabu
//
//  Created by 千代田桃 on 10/30/22.
//

#import "DeckStatsWindow.h"
#import "DeckManager.h"
#import <KaniManabu-Swift.h>

@interface DeckStatsWindow ()
@property (strong) DeckManager *dm;
@property (strong) IBOutlet NSView *chartview;
@property (strong) IBOutlet NSToolbarItem *chartselector;
@property (strong) IBOutlet NSSegmentedControl *chartselectorsegment;
@end

@implementation DeckStatsWindow
- (instancetype)init {
    self = [super initWithWindowNibName:@"DeckStatsWindow"];
    if (!self)
        return nil;
    self.dm = [DeckManager sharedInstance];
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [_chartview addSubview:[NSView new]];
    _chartview.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
}

- (void)loadChart {
    if (!_deckuuid) {
        // No Deck UUID specified, abort
        return;
    }
    ChartCreator *cc = [ChartCreator new];
    if (_chartselectorsegment.selectedSegment == 0) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[_dm generateForecastDataforDeckUUID:_deckuuid]
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (! jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSViewController *vc = [cc generateStackedBarLineChartWithData:jsonString];
            if (vc) {
                // Add chart view
                vc.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
                NSRect chartviewframe = _chartview.frame;
                NSPoint origin = NSMakePoint(0, 0);
                [_chartview replaceSubview:(_chartview.subviews)[0] with:vc.view];
                vc.view.frame = chartviewframe;
                [vc.view setFrameOrigin:origin];
            }
        }
    }
    else {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_chartselectorsegment.selectedSegment == 1 ? [_dm generateLearnedChartDataforDeckUUID:_deckuuid] : [_dm generateSRSChartDataforDeckUUID:_deckuuid]
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (! jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSViewController *vc = [cc generateSingleBarChartWithData:jsonString];
            if (vc) {
                // Add chart view
                vc.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
                NSRect chartviewframe = _chartview.frame;
                NSPoint origin = NSMakePoint(0, 0);
                [_chartview replaceSubview:(_chartview.subviews)[0] with:vc.view];
                vc.view.frame = chartviewframe;
                [vc.view setFrameOrigin:origin];
            }
        }
    }
}
- (IBAction)segchanged:(id)sender {
    [self loadChart];
}

@end
