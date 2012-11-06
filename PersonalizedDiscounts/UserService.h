//
//  UserService.h
//  PersonalizedDiscounts
//
//  Created by sathish on 11/5/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//
#import <FacebookSDK/FacebookSDK.h>
#import <Foundation/Foundation.h>

@interface UserService : NSObject{
    FBSession *session;
   
    
}
@property (readonly) NSString *email;
@property (readonly) NSString *username;
@property (readonly) NSString *firstname;
@property (readonly) NSString *lastname;
+(UserService *) sharedInstance;
-(void)authenticate:(id)hostController;
-(void)login:(id)hostController;
-(void)logout;
@end
