/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "LoginViewController.h"
#import "MSAppDelegate.h"
#import "MSScannerController.h"
#import "DiscountService.h"

@interface LoginViewController ()

- (void)updateView;

@end

@implementation LoginViewController

@synthesize authButton = _authButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _lastSync = 0;
        
        // This is useful to turn on auto-sync when the app re-enters the foreground
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        // Please refer to the synchronization policy notes below for more details
        [self sync];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self updateView];
    
    MSAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (!appDelegate.session.isOpen) {
        // create a fresh session object
        appDelegate.session = [[FBSession alloc] init];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
                // we recurse here, in order to update buttons and labels
                [self updateView];
            }];
        }
    }
    [self.scanButton addTarget:self action:@selector(scanAction) forControlEvents:UIControlEventTouchDown];
}

- (void)scanAction {
    MSScannerController *scannerController = [[MSScannerController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scannerController];
    
    [self presentModalViewController:navController animated:YES];
    
    [scannerController release];
    [navController release];
}

// FBSample logic
// main helper method to update the UI to reflect the current state of the session.
- (void)updateView {
    // get the app delegate, so that we can reference the session property
    MSAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isOpen) {
        // valid account UI is shown whenever the session is open
        [self.authButton setTitle:@"Log Out"];
        [self.scanButton setHidden:NO];
    } else {
        // login-needed account UI is shown whenever the session is closed
        [self.authButton setTitle:@"Log In"];
        [self.scanButton setHidden:YES];
    }
}

#pragma mark Template generated code


- (void)viewDidUnload
{
    [self setAuthButton:nil];
    [self setScanButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark -

- (void)dealloc {
    [_authButton release];
    [_scanButton release];
    [super dealloc];
}
- (IBAction)loginPressed:(UIBarButtonItem *)sender {
    // get the app delegate so that we can access the session property
    MSAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    // this button's job is to flip-flop the session from open to closed
    if (appDelegate.session.isOpen) {
        // if a user logs out explicitly, we delete any cached token information, and next
        // time they run the applicaiton they will be presented with log in UX again; most
        // users will simply close the app or switch away, without logging out; this will
        // cause the implicit cached-token login to occur on next launch of the application
        [appDelegate.session closeAndClearTokenInformation];
        
    } else {
        if (appDelegate.session.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            appDelegate.session = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                         FBSessionState status,
                                                         NSError *error) {
            // and here we make sure to update our UX according to the new session state
            [self updateView];
        }];
    }

}
- (IBAction)scanPressed:(id)sender {
}

// -------------------------------------------------
// NOTES AROUND THE CACHE SYNCHRONIZATION POLICY
// -------------------------------------------------
//
// Here's a recap about the synchronization policy retained within this demo app:
//
//                       | SYNC
// ----------------------------------------------
// (1) COLD START        | yes
// (2) LAUNCH            | yes
// (3) ENTER FOREGROUND  | if last sync > 1 day
//
// (1) Cold start = the image database is empty (i.e. no successful sync occurred yet).
//
// (2) Launch = the app starts with a non empty database.
//
// (3) Enter foreground = the app has been switched in background then foreground, and the
//     database is not empty. Do the same as above except avoid performing a sync except if
//     the last successful sync is too old (1 day here).
//
// NOTE: according to the frequency at which you update your API key with new/modified images
//       you may want to adapt this 1 day parameter to make sure the cache stays up to date.

#pragma mark -
#pragma mark Moodstocks SDK Synchronization

- (void)applicationWillEnterForeground {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastSync >= 86400.0 /* seconds */)
        [self sync];
}

- (void)sync {
#if MS_SDK_REQUIREMENTS
    MSScanner *scanner = [MSScanner sharedInstance];
    
    if ([scanner isSyncing])
        return;
    
    [scanner syncWithDelegate:self];
#endif
}

#pragma mark - MSScannerDelegate

#if MS_SDK_REQUIREMENTS
-(void)scannerWillSync:(MSScanner *)scanner {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    MSDLog(@" [MOODSTOCKS SDK] WILL SYNC ");
}

- (void)scannerDidSync:(MSScanner *)scanner {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    _lastSync = [[NSDate date] timeIntervalSince1970];
    
    MSDLog(@" [MOODSTOCKS SDK] DID SYNC. DATABASE SIZE = %d IMAGE(S)", [scanner count:nil]);
}

- (void)scanner:(MSScanner *)scanner failedToSyncWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    ms_errcode ecode = [error code];
    
    // NOTE: we ignore negative error codes which are not returned by the SDK
    //       but application specific (e.g. so far -1 is returned when cancelling)
    if (ecode >= 0 && ecode != MS_BUSY) {
        ms_errcode ecode = [error code];
        NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
        
        MSDLog(@" [MOODSTOCKS SDK] FAILED TO SYNC WITH ERROR: %@", errStr);
    }
}
#endif

@end
