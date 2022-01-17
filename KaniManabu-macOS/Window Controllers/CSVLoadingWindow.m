//
//  CSVLoadingWindow.m
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/17/22.
//

#import "CSVLoadingWindow.h"

@interface CSVLoadingWindow ()
@property (strong) IBOutlet NSProgressIndicator *progresswheel;

@end

@implementation CSVLoadingWindow
- (instancetype)init {
    self = [super initWithWindowNibName:@"CSVLoadingWindow"];
    if (!self)
        return nil;
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self.progresswheel startAnimation:self];
}

- (void)operationDone {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    [self.window close];
}
@end
