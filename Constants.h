//
//  Constants.h
//  PersonalizedDiscounts
//
//  Created by sathish on 11/8/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#ifndef PersonalizedDiscounts_Constants_h
#define PersonalizedDiscounts_Constants_h

#pragma mark - Instances
#ifdef DEVELOPMENT
#define DISCOUNT_SERVICE_URL @"http://snoopy.apphb.com/api/discounts/%@/%@"
#endif

#ifdef STAGING
#define DISCOUNT_SERVICE_URL @"http://snoopy.apphb.com/api/discounts/%@/%@"
#endif

#ifdef PRODUCTION
#define DISCOUNT_SERVICE_URL @"http://snoopy.apphb.com/api/discounts/%@/%@"
#endif

#endif
