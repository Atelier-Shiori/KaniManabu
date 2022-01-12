//
//  DeckViewCell.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeckViewCell : NSTableCellView
@property (strong) IBOutlet NSTextField *DeckName;
@property (strong) IBOutlet NSTextField *reviewcount;
@property (strong) IBOutlet NSTextField *learningcount;
@property (strong) NSManagedObject *deckMeta;
@property (strong) IBOutlet NSTextField *decktypestr;
- (void)reloadQueueCount;
- (void)setDeckTypeLabel;
@end

NS_ASSUME_NONNULL_END
