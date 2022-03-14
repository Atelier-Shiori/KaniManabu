//
//  AppDelegate.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "MainWindowController.h"

#if defined(AppStore)
#import <RevenueCat/RevenueCat-Swift.h>
#else
#endif
#if defined(AppStore)
@interface AppDelegate : NSObject <NSApplicationDelegate, RCPurchasesDelegate>
#else
@interface AppDelegate : NSObject <NSApplicationDelegate>
#endif
@property (readonly, strong) NSPersistentCloudKitContainer *persistentContainer;
@property (readonly, strong) NSPersistentContainer *wanikaniContainer;
@property (readonly, strong) NSPersistentContainer *audioContainer;
@property (strong) MainWindowController *mwc;
@property (strong) NSWindowController *_preferencesWindowController;

@end

