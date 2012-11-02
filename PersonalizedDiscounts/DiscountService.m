//
//  DiscountService.m
//  PersonalizedDiscounts
//
//  Created by sathish on 11/2/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import "DiscountService.h"

@interface DiscountService(){
    NSMutableData *receivedData;
}
@end

@implementation DiscountService

//Should be changed according to environment
#ifdef DEBUG
NSString* const MSServerUrl = @"http://snoopy.apphb.com/api/discounts/%@/%@";
#else
NSString* const MSServerUrl = @"http://snoopy.apphb.com/api/discounts/%@/%@";
#endif

-(NSString*) getDiscountForProduct:(NSString *)productId
                            User:(NSString *)userId{
    NSString *urlString =[NSString stringWithFormat:MSServerUrl,userId,productId];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSError *error;
    NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    NSDictionary *result = [self getDictionaryFromJsonString:data];
    NSLog(@"%@", [result objectForKey:@"Off"]);
    return [result objectForKey:@"Off"];
}

- (id) getDictionaryFromJsonString:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return result;
}

@end