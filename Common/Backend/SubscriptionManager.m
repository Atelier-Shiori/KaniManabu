//
//  SubscriptionManager.m
//  KaniManabu
//
//  Created by 千代田桃 on 3/11/22.
//

#import "SubscriptionManager.h"
#import "DeckManager.h"

@implementation SubscriptionManager
+ (void)getOfferingsWithcompletionHandler:(void (^)(bool success, RCOfferings *offerings)) completionHandler {
    [[RCPurchases sharedPurchases] getOfferingsWithCompletion:^(RCOfferings *offerings, NSError *error) {
        if (offerings.current && offerings.current.availablePackages.count != 0) {
            completionHandler(true, offerings);
        }
        else {
            completionHandler(false, nil);
        }
    }];
}
+ (void)setDonationStateWithCustomer:(RCCustomerInfo *)customerInfo {
    if (customerInfo.entitlements[@"subscribed"].isActive) {
      // Unlock that great "pro" content
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"donated"];
    }
    else {
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"donated"];
    }
}
+ (void)purchasePackage:(RCPackage *)package completionHandler:(void (^)(bool success, bool cancelled)) completionHandler {
    [[RCPurchases sharedPurchases] purchasePackage:package withCompletion:^(RCStoreTransaction *transaction, RCCustomerInfo *customerInfo, NSError *error, BOOL cancelled) {
        [self setDonationStateWithCustomer:customerInfo];
    }];
}
+ (void)restorePurchase:(void (^)(bool success)) completionHandler {
    [[RCPurchases sharedPurchases] restorePurchasesWithCompletion:^(RCCustomerInfo *customerInfo, NSError *error) {
        //... check customerInfo to see if entitlement is now active
        if (error) {
            completionHandler(false);
        }
        else {
            if (customerInfo.entitlements[@"subscribed"].isActive) {
                [self setDonationStateWithCustomer:customerInfo];
                completionHandler(true);
            }
            else {
                completionHandler(false);
            }
        }
    }];
}

+ (void)getCustomerInfo:(void (^)(bool success, RCCustomerInfo * customerInfo)) completionHandler {
    [[RCPurchases sharedPurchases] getCustomerInfoWithCompletion:^(RCCustomerInfo * _Nullable customerinfo, NSError * _Nullable error) {
        if (error) {
            completionHandler(false, nil);
        }
        else {
            completionHandler(true, customerinfo);
        }
    }];
}
+ (bool)checkDeckLimit:(bool)adding {
    bool donated = [NSUserDefaults.standardUserDefaults boolForKey:@"donated"];
    if (donated) {
        return true;
    }
    else {
        if (adding) {
            if ([DeckManager.sharedInstance retrieveDecks].count < 3) {
                return true;
            }
        }
        else {
            if ([DeckManager.sharedInstance retrieveDecks].count <= 3) {
                return true;
            }
        }
    }
    return false;
}
@end
