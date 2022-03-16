//
//  PreferencesControllers.h
//  WaniManabu
//
//  Created by 丈槍由紀 on 1/10/22.
//

#import "GeneralPreferencesViewController.h"
#import "WaniKaniPreferences.h"
#import <MASPreferences/MASPreferences.h>
#import "AdvancedPref.h"
#if defined(AppStore)
#import "SubscriptionPref.h"
#else
#import "SoftwareUpdatesPref.h"
#endif
