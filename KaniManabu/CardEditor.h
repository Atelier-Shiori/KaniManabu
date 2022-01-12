//
//  CardEditor.h
//  KaniManabu
//
//  Created by 千代田桃 on 1/12/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CardEditor : NSObject
+ (void)openVocabCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler;
+ (void)openKanjiCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler;
+ (void)openKanaCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler;
@end

NS_ASSUME_NONNULL_END
