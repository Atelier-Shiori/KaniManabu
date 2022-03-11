//
//  SubscriptionManager.h
//  KaniManabu
//
//  Created by 千代田桃 on 3/11/22.
//

#import <Foundation/Foundation.h>

#import <RevenueCat/RevenueCat-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionManager : NSObject
+ (void)getOfferingsWithcompletionHandler:(void (^)(bool success, RCOfferings *offerings)) completionHandler;
+ (void)setDonationStateWithCustomer:(RCCustomerInfo *)customerInfo;
+ (void)purchasePackage:(RCPackage *)package completionHandler:(void (^)(bool success, bool cancelled)) completionHandler;
+ (void)restorePurchase:(void (^)(bool success)) completionHandler;
+ (void)getCustomerInfo:(void (^)(bool success, RCCustomerInfo * customerInfo)) completionHandler;
@end

NS_ASSUME_NONNULL_END
