//
//  CredentialManager.m
//  PersonalizedDiscounts
//
//  Created by sathish on 10/30/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//


#import "MSDebug.h"
#import "CredentialManager.h"
#import <FacebookSDK/FacebookSDK.h>


@implementation CredentialManager

+ (void) authorize
{
    MSDLog(@"\nAuthorizing");
    if (FBSession.activeSession.isOpen) {
        // login is integrated with the send button -- so if open, we send
        MSDLog(@"\nSession already open");
        
    } else {
        [FBSession openActiveSessionWithReadPermissions:nil
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session,
                                                          FBSessionState status,
                                                          NSError *error) {
                                          MSDLog(@"\nStatus %@",[(NSString *)status description]);
                                          // if login fails for any reason, we alert
                                          if (error) {
                                              [CredentialManager authorize];
                                              // if otherwise we check to see if the session is open, an alternative to
                                              // to the FB_ISSESSIONOPENWITHSTATE helper-macro would be to check the isOpen
                                              // property of the session object; the macros are useful, however, for more
                                              // detailed state checking for FBSession objects
                                          } else if (FB_ISSESSIONOPENWITHSTATE(status)) {
                                              // send our requests if we successfully logged in
                                              MSDLog(@"\nSuccessfully logged in");
                                          }
                                      }];
    }
    
}

@end
