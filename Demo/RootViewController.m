/**
 * Copyright (c) 2012 Moodstocks SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "RootViewController.h"

#import "MSScannerController.h"
#import "MSDebug.h"

@interface RootViewController ()

- (void)scanAction;
- (void)applicationWillEnterForeground;
- (void)sync;

@end

@implementation RootViewController

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void) loadView {
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    self.view = [[[UIView alloc] initWithFrame:frame] autorelease];
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat bw = 160.0;
    CGFloat bh = 40.0;
    CGFloat ww = self.view.frame.size.width;
    CGFloat hh = self.view.frame.size.height - 44.0;
    
    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [scanButton addTarget:self action:@selector(scanAction) forControlEvents:UIControlEventTouchDown];
    [scanButton setTitle:@"Scan" forState:UIControlStateNormal];
    scanButton.frame = CGRectMake(0.5 * (ww - bw), 0.5 * (hh - bh), bw, bh);
    [self.view addSubview:scanButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Demo";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI Actions

- (void)scanAction {
    MSScannerController *scannerController = [[MSScannerController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scannerController];
    
    [self presentModalViewController:navController animated:YES];
    
    [scannerController release];
    [navController release];
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
