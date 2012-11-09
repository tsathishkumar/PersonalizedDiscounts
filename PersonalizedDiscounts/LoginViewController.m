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
#import "AKOverlayViewController.h"

@interface LoginViewController ()

- (void)updateView;

@property (nonatomic, retain) NSTimer *splashTimer;

- (void)showSplash;
- (void)createAurasmaController;
- (void)launchAurasmaShowingCloseButton:(BOOL)showCloseButton animated:(BOOL)animated;

@end

@implementation LoginViewController

@synthesize aurasmaController;
@synthesize launchButton;
@synthesize splashTimer;


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
    
    [[UserService sharedInstance] authenticate:self];
    
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

        NSString* username = [NSString stringWithFormat:@"%@ %@", [UserService sharedInstance].firstname, [UserService sharedInstance].lastname];
        if(username) {
            [self.welcomeLabel setText:[NSString stringWithFormat:@"Welcome %@",username]];
        }
        // valid account UI is shown whenever the session is open
        [self.authButton setTitle:@"Log Out"];
        [self.scanButton setHidden:NO];
        [self.launchButton setHidden:NO];
    } else {
        // login-needed account UI is shown whenever the session is closed
        [self.welcomeLabel setText:@"Please login to use the app"];
        [self.authButton setTitle:@"Log In"];
        [self.scanButton setHidden:YES];
        [self.launchButton setHidden:YES];
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
    [_welcomeLabel release];
    [super dealloc];
}
- (IBAction)loginPressed:(UIBarButtonItem *)sender {
    // get the app delegate, so that we can reference the session property
    MSAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isOpen) {
        [[UserService sharedInstance] logout];
    } else {
        [[UserService sharedInstance] login:self];
    }
    [self updateView];
    
}

- (IBAction)scanPressed:(id)sender {
}

- (void)showSplash
{
    CGRect splashFrame = [self.view convertRect:[[UIScreen mainScreen] applicationFrame] fromView:nil];
    
    UIImageView *splashView = [[[UIImageView alloc] initWithFrame:splashFrame] autorelease];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        splashView.image = [UIImage imageNamed:@"Default~ipad"];
    else
        splashView.image = [UIImage imageNamed:@"Default"];
    
    splashView.tag = 1;
    [self.view addSubview:splashView];
    
    // Show splash for 2 seconds, or until we've finished unpacking resources (whichever is longer)
    self.splashTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(splashFinished:) userInfo:nil repeats:NO];
}

- (void)splashFinished:(NSTimer*)timer
{
    self.splashTimer = nil;
    
#if START_IMMEDIATELY
    // Show the AKViewController if it has finished loading
    if([self.aurasmaController isLoaded])
        [self launchAurasmaShowingCloseButton:NO animated:NO];
#else
    UIView *splashView = [self.view viewWithTag:1];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         splashView.alpha = 0.0;
                     }
                     completion: ^(BOOL finished){
                         [splashView removeFromSuperview];
                         [[UIApplication sharedApplication] setStatusBarHidden:NO];
                         
                     }];
#endif
}

- (void)createAurasmaController
{
    if( !self.aurasmaController )
    {
        self.aurasmaController = [AKViewController aurasmaViewControllerWithDelegate:self];
        
        
        //        [self.aurasmaController addButtonWithTarget:self
        //                                             action:@selector(buttonPressed:)
        //                                              image:[UIImage imageNamed:@"test.png"]
        //                                      selectedImage:[UIImage imageNamed:@"test_sel.png"]];
        
    }
}

- (void)launchAurasmaShowingCloseButton:(BOOL)showCloseButton animated:(BOOL)animated
{
    [self createAurasmaController];
    
    if (self.aurasmaController)
    {
        self.aurasmaController.showsCloseButton = showCloseButton;
        self.aurasmaController.delayGuide = YES;
        [self presentModalViewController:self.aurasmaController animated:animated];
    }
    else
        [[[[UIAlertView alloc] initWithTitle:@"Alert"
                                     message:@"AurasmaKit not supported on this architecture"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
}

#pragma mark -
#pragma mark Manual Launch
- (IBAction)launchPressed:(id)sender
{
    [self launchAurasmaShowingCloseButton:YES animated:YES];
}

#pragma mark -
#pragma mark AKViewControllerDelegate

- (void)aurasmaViewControllerDidClose:(AKViewController*)aurasmaViewController
{
    self.aurasmaController.delegate = nil;
    self.aurasmaController = nil;
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)aurasmaViewControllerDidFinishLoading:(AKViewController*)aurasmaViewController
{
    // Show the AKViewController if we've finished showing the splash
    if(!splashTimer)
        [self launchAurasmaShowingCloseButton:NO animated:NO];
    
}

- (void) aurasmaViewController:(AKViewController*)aurasmaViewController didLoadOverlayView:(UIView*)overlayView
{
    //    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //
    //    button.frame  = CGRectMake(0., 0., 150.0, overlayView.bounds.size.height);
    //    [button setTitle: @"Press me!" forState:UIControlStateNormal];
    //
    //    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    //
    //    [overlayView addSubview:button];
}

#pragma mark -
#pragma mark OverlayViewController

- (void)buttonPressed: (id)sender
{
    AKOverlayViewController *overlayController = [[[AKOverlayViewController alloc] initWithNibName:@"AKOverlayViewController" bundle:nil] autorelease];
    overlayController.delegate = self;
    
    [self.aurasmaController presentOverlayViewController:overlayController animated:YES];
}

- (void)overlayViewControllerDidFinish:(AKOverlayViewController*)controller
{
    [self.aurasmaController dismissOverlayViewControllerAnimated:YES];
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
    
    NSLog(@" [MOODSTOCKS SDK] WILL SYNC ");
}

- (void)scannerDidSync:(MSScanner *)scanner {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    _lastSync = [[NSDate date] timeIntervalSince1970];
    
    NSLog(@" [MOODSTOCKS SDK] DID SYNC. DATABASE SIZE = %d IMAGE(S)", [scanner count:nil]);
}

- (void)scanner:(MSScanner *)scanner failedToSyncWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    ms_errcode ecode = [error code];
    
    // NOTE: we ignore negative error codes which are not returned by the SDK
    //       but application specific (e.g. so far -1 is returned when cancelling)
    if (ecode >= 0 && ecode != MS_BUSY) {
        ms_errcode ecode = [error code];
        NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
        
        NSLog(@" [MOODSTOCKS SDK] FAILED TO SYNC WITH ERROR: %@", errStr);
    }
}
#endif

@end
