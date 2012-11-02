//
//  DiscountService.h
//  PersonalizedDiscounts
//
//  Created by sathish on 11/2/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiscountService : NSObject

-(NSString*) getDiscountForProduct:(NSString *)productId
                            User:(NSString *)userId;
@end
