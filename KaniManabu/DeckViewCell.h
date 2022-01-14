//
//  DeckViewCell.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import <Cocoa/Cocoa.h>



@interface DeckViewCell : NSTableCellView
@property (strong) IBOutlet NSTextField *DeckName;
@property (strong) IBOutlet NSTextField *reviewcount;
@property (strong) IBOutlet NSTextField *learningcount;
@property (strong) NSManagedObject *deckMeta;
@property (strong) IBOutlet NSTextField *decktypestr;
@property long totalreviewitemcount;
@property long totallearnitemcount;
- (void)reloadQueueCount;
- (void)setDeckTypeLabel;
@end


