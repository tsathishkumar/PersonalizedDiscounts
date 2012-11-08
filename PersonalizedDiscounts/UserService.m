//
//  UserService.m
//  PersonalizedDiscounts
//
//  Created by sathish on 11/5/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import "UserService.h"
#import "MSAppDelegate.h"

@implementation UserService

static UserService *service = nil;
MSAppDelegate *appDelegate;
@synthesize email;
@synthesize username;
@synthesize firstname;
@synthesize lastname;

+(UserService *)sharedInstance{
    if(!service){
        service = [[UserService alloc] init];
    }
    return service;
}

-(void)authenticate:(id)hostController{
    if(!appDelegate) {
        appDelegate = [[UIApplication sharedApplication]delegate];
    }
    if (!appDelegate.session.isOpen) {
        // create a fresh session object
        appDelegate.session = [[FBSession alloc] initWithPermissions:@[@"email"]];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded || appDelegate.session.state == FBSessionStateCreated) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session openWithCompletionHandler:^(FBSession *fbSession,
                                                             FBSessionState status,
                                                             NSError *error) {
                
                [self collectUserDetails:hostController];
            }];
        }
    } else {
        [self collectUserDetails:hostController];
    }

}

-(void)login:(id)hostController{
    if (appDelegate.session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        appDelegate.session = [[FBSession alloc] init];
    }
    
    // if the session isn't open, let's open it now and present the login UX to the user
    [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error) {
        // and here we make sure to update our UX according to the new session state
        [self collectUserDetails:hostController];
    }];
}

-(void)logout{
    [appDelegate.session closeAndClearTokenInformation];
}

-(void) collectUserDetails:(id)hostController {
    [[[FBRequest alloc] initWithSession:appDelegate.session graphPath:@"me"] startWithCompletionHandler:^(FBRequestConnection *connection,
                                                                                                          id result,
                                                                                                          NSError *error) {
        NSDictionary *my = (NSDictionary*) result;
        NSLog(@"json: %@",[my description]);
        self.email = [my objectForKey:@"email"];
        NSLog(@"email: %@",self.email);
        self.username = [my objectForKey:@"username"];
        NSLog(@"username: %@",self.username);
        self.firstname = [my objectForKey:@"first_name"];
        NSLog(@"firstname: %@",self.firstname);
        self.lastname = [my objectForKey:@"last_name"];
        NSLog(@"lastname: %@",self.lastname);
        [hostController updateView];
    }];
}

@end
