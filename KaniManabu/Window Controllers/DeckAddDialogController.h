//
//  DeckAddDialogController.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckAddDialogController : NSWindowController
@property (strong) IBOutlet NSTextField *deckname;
@property (strong) IBOutlet NSPopUpButton *typebtn;

@end

NS_ASSUME_NONNULL_END
