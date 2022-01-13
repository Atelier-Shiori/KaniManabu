//
//  CardEditor.m
//  KaniManabu
//
//  Created by 千代田桃 on 1/12/22.
//

#import "CardEditor.h"
#import "DeckManager.h"
#import "VocabEditor.h"
#import "KanaEditor.h"
#import "KanjiEditor.h"

@implementation CardEditor
+ (void)openVocabCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler {
    VocabEditor *ve = [VocabEditor new];
    if (!newCard) {
        ve.cardUUID = uuid;//[_arraycontroller selectedObjects][0][@"carduuid"];
    }
    else {
        ve.deckUUID = uuid;//_currentDeckUUID;
    }
    ve.newcard = newCard;
    [w beginSheet:ve.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            if (newCard) {
                if ([DeckManager.sharedInstance checkCardExistsInDeckWithDeckUUID:ve.deckUUID withJapaneseWord:ve.cardSaveData[@"japanese"] withType:DeckTypeVocab]) {
                    NSAlert *alert = [[NSAlert alloc] init] ;
                    [alert addButtonWithTitle:@"OK"];
                    [alert setMessageText:@"Card already exists in deck"];
                    alert.informativeText = [NSString stringWithFormat:@"A card with %@ already exists in the deck.", ve.cardSaveData[@"japanese"]];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                        completionHandler(false);
                        }];
                }
                else {
                    if ([DeckManager.sharedInstance addCardWithDeckUUID:ve.deckUUID withCardData:ve.cardSaveData withType:DeckTypeVocab]) {
                        completionHandler(true);
                    }
                    else {
                        NSAlert *alert = [[NSAlert alloc] init] ;
                        [alert addButtonWithTitle:@"OK"];
                        [alert setMessageText:@"Couldn't create card."];
                        alert.informativeText = [NSString stringWithFormat:@"%@ failed to create.", ve.cardSaveData[@"japanese"]];
                        alert.alertStyle = NSAlertStyleInformational;
                        [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                            completionHandler(false);
                            }];
                    }
                }
            }
            else {
                if ([DeckManager.sharedInstance modifyCardWithCardUUID:ve.cardUUID withCardData:ve.cardSaveData withType:DeckTypeVocab]) {
                    completionHandler(true);
                }
            }
        }
    }];
}

+ (void)openKanjiCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler {
    KanjiEditor *kje = [KanjiEditor new];
    if (!newCard) {
        kje.cardUUID = uuid;
    }
    else {
        kje.deckUUID = uuid;
    }
    kje.newcard = newCard;
    [w beginSheet:kje.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            if (newCard) {
                if ([DeckManager.sharedInstance checkCardExistsInDeckWithDeckUUID:kje.deckUUID withJapaneseWord:kje.cardSaveData[@"japanese"] withType:DeckTypeKanji]) {
                    NSAlert *alert = [[NSAlert alloc] init] ;
                    [alert addButtonWithTitle:@"OK"];
                    [alert setMessageText:@"Card already exists in deck"];
                    alert.informativeText = [NSString stringWithFormat:@"A card with %@ already exists in the deck.", kje.cardSaveData[@"japanese"]];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                        completionHandler(false);
                        }];
                }
                else {
                    if ([DeckManager.sharedInstance addCardWithDeckUUID:kje.deckUUID withCardData:kje.cardSaveData withType:DeckTypeKanji]) {
                        completionHandler(true);
                    }
                    else {
                        NSAlert *alert = [[NSAlert alloc] init] ;
                        [alert addButtonWithTitle:@"OK"];
                        [alert setMessageText:@"Couldn't create card."];
                        alert.informativeText = [NSString stringWithFormat:@"%@ failed to create.", kje.cardSaveData[@"japanese"]];
                        alert.alertStyle = NSAlertStyleInformational;
                        [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                            completionHandler(false);
                            }];
                    }
                }
            }
            else {
                if ([DeckManager.sharedInstance modifyCardWithCardUUID:kje.cardUUID withCardData:kje.cardSaveData withType:DeckTypeKanji]) {
                    completionHandler(true);
                }
            }
        }
    }];
}

+ (void)openKanaCardEditorWithUUID:(NSUUID *)uuid isNewCard:(bool)newCard withWindow:(NSWindow *)w completionHandler:(void (^)(bool success)) completionHandler {
    KanaEditor *ke = [KanaEditor new];
    if (!newCard) {
        ke.cardUUID = uuid;
    }
    else {
        ke.deckUUID = uuid;
    }
    ke.newcard = newCard;
    [w beginSheet:ke.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            if (newCard) {
                if ([DeckManager.sharedInstance checkCardExistsInDeckWithDeckUUID:ke.deckUUID withJapaneseWord:ke.cardSaveData[@"japanese"] withType:DeckTypeKana]) {
                    NSAlert *alert = [[NSAlert alloc] init] ;
                    [alert addButtonWithTitle:@"OK"];
                    [alert setMessageText:@"Card already exists in deck"];
                    alert.informativeText = [NSString stringWithFormat:@"A card with %@ already exists in the deck.", ke.cardSaveData[@"japanese"]];
                    alert.alertStyle = NSAlertStyleInformational;
                    [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                        completionHandler(false);
                        }];
                }
                else {
                    if ([DeckManager.sharedInstance addCardWithDeckUUID:ke.deckUUID withCardData:ke.cardSaveData withType:DeckTypeKana]) {
                        completionHandler(true);
                    }
                    else {
                        NSAlert *alert = [[NSAlert alloc] init] ;
                        [alert addButtonWithTitle:@"OK"];
                        [alert setMessageText:@"Couldn't create card."];
                        alert.informativeText = [NSString stringWithFormat:@"%@ failed to create.", ke.cardSaveData[@"japanese"]];
                        alert.alertStyle = NSAlertStyleInformational;
                        [alert beginSheetModalForWindow:w completionHandler:^(NSModalResponse returnCode) {
                            completionHandler(false);
                            }];
                    }
                }
            }
            else {
                if ([DeckManager.sharedInstance modifyCardWithCardUUID:ke.cardUUID withCardData:ke.cardSaveData withType:DeckTypeKana]) {
                    completionHandler(true);
                }
            }
        }
    }];
}
@end
