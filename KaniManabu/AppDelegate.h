//
//  AppDelegate.h
//  WaniManabu
//
//  Created by 千代田桃 on 1/10/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "MainWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong) NSPersistentCloudKitContainer *persistentContainer;
@property (strong) MainWindowController *mwc;
@property (strong) NSWindowController *_preferencesWindowController;

@end

