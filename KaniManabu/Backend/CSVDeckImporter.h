//
//  CSVDeckImporter.h
//  KaniManabu
//
//  Created by 千代田桃 on 1/14/22.
//

#import <Foundation/Foundation.h>
#import "DeckManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSVDeckImporter : NSObject
@property (strong) NSArray *csvcolumns;
@property (strong) NSArray *loadedcsvdata;
@property (strong) NSArray *destinationmap;
- (void)loadCSVWithURL:(NSURL *)url completionHandler:(void (^)(bool success, NSArray *columnnames)) completionHandler;
- (void)performimportWithDeckName:(NSString *)deckname withDeckType:(int)type destinationMap:(NSArray *)map completionHandler:(void (^)(bool success)) completionHandler;
@end

NS_ASSUME_NONNULL_END
