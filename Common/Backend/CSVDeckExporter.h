//
//  CSVDeckExporter.h
//  KaniManabu
//
//  Created by 丈槍由紀 on 1/16/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSVDeckExporter : NSObject
+ (void)exportDeckwithDeck:(NSManagedObject *)deck withURL:(NSURL *)url completionHandler:(void (^)(bool success)) completionHandler;
@end

NS_ASSUME_NONNULL_END
