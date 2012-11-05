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

#import "MSScannerController.h"

#import "MSOverlayController.h"
#import "MSDebug.h"
#import "MSImage.h"

#include "moodstocks_sdk.h"

#if MS_SDK_REQUIREMENTS
/**
 * Enabled scanning formats
 * Here we allow offline image recognition as well as EAN13 and QRCodes barcode decoding.
 * Feel free to add `MS_RESULT_TYPE_EAN8` if you want in addition to decode EAN-8.
 */
static NSInteger kMSScanOptions = MS_RESULT_TYPE_IMAGE |
                                  MS_RESULT_TYPE_EAN13 |
                                  MS_RESULT_TYPE_QRCODE;

/* Do not modify */
static void ms_avcapture_cleanup(void *p) {
    [((MSScannerController *) p) release];
}
#endif

/* Private stuff */
@interface MSScannerController ()

#if MS_SDK_REQUIREMENTS
- (void)deviceOrientationDidChange;
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *)backFacingCamera;
#endif

- (void)startCapture;
- (void)stopCapture;

- (void)showFlash;
- (void)setActivityView:(BOOL)show;

- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer;
- (void)dismissAction;

@end


@implementation MSScannerController

#if MS_SDK_REQUIREMENTS
@synthesize captureSession;
@synthesize previewLayer;
@synthesize orientation;
#endif

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *barButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(dismissAction)] autorelease];
        self.navigationItem.leftBarButtonItem = barButton;
        
        _scannerSession = [[MSScannerSession alloc] initWithScanner:[MSScanner sharedInstance]];

#if MS_SDK_REQUIREMENTS
        // This is to register to the API search notifications triggered by the snap & send mode
        _scannerSession.delegate = self;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        self.orientation = AVCaptureVideoOrientationPortrait;
#endif
        
        _overlayController = [[MSOverlayController alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_overlayController release];
    _overlayController = nil;
    
    [_scannerSession release];
    
    [_result release];
    _result = nil;
    
#if MS_SDK_REQUIREMENTS
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
#endif
    
    [super dealloc];
}

#pragma mark - Private stuff

#if MS_SDK_REQUIREMENTS
- (void)deviceOrientationDidChange {	
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
	if (deviceOrientation == UIDeviceOrientationPortrait)
		self.orientation = AVCaptureVideoOrientationPortrait;
	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
		self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
		self.orientation = AVCaptureVideoOrientationLandscapeRight;
	else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
		self.orientation = AVCaptureVideoOrientationLandscapeLeft;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}
#endif

- (void)startCapture {
#if MS_SDK_REQUIREMENTS    
    // == CAPTURE SESSION SETUP
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    AVCaptureVideoDataOutput *newCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("MSScannerController", DISPATCH_QUEUE_SERIAL);
    dispatch_set_context(videoDataOutputQueue, self);
    dispatch_set_finalizer_f(videoDataOutputQueue, ms_avcapture_cleanup);
    [newCaptureOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    dispatch_release(videoDataOutputQueue);
    [self retain]; /* a release is made at `ms_avcapture_cleanup` time */
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                               forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [newCaptureOutput setVideoSettings:outputSettings];
    [newCaptureOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    AVCaptureSession *cSession = [[AVCaptureSession alloc] init];
    self.captureSession = cSession;
    [cSession release];
    
    // == FRAMES RESOLUTION
    // NOTE: these are recommended settings, do *NOT* change
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    if ([self.captureSession canAddInput:newVideoInput]) {
        [self.captureSession addInput:newVideoInput];
    }
    else {
        // Fallback to 480x360 (e.g. on 3GS devices)
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetMedium])
            [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
        if ([self.captureSession canAddInput:newVideoInput]) {
            [self.captureSession addInput:newVideoInput];
        }
    }
    
    if ([self.captureSession canAddOutput:newCaptureOutput])
        [self.captureSession addOutput:newCaptureOutput];
    
    [newVideoInput release];
    [newCaptureOutput release];
    
    // == VIDEO PREVIEW SETUP
    if (!self.previewLayer)
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    UIView *videoPreviewView = nil;
    for (UIView *v in [self.view subviews]) {
        if ([v tag] == 1) {
            videoPreviewView = v;
            
            CALayer *viewLayer = [videoPreviewView layer];
            [viewLayer setMasksToBounds:YES];
            [self.previewLayer setFrame:[videoPreviewView bounds]];
            if ([self.previewLayer isOrientationSupported])
                [self.previewLayer setOrientation:AVCaptureVideoOrientationPortrait];
            [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            [viewLayer insertSublayer:self.previewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
            
            break;
        }
    }
    
    [self.captureSession startRunning];
    
    // == OVERLAY NOTIFICATION
    NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_EAN8)],   @"decode_ean_8",
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_EAN13)],  @"decode_ean_13",
                           [NSNumber numberWithBool:!!(kMSScanOptions & MS_RESULT_TYPE_QRCODE)], @"decode_qrcode", nil];
    [_overlayController scanner:self stateUpdated:state];
#endif
}

- (void)stopCapture {
#if MS_SDK_REQUIREMENTS
    [captureSession stopRunning];
    
    AVCaptureInput *input = [captureSession.inputs objectAtIndex:0];
    [captureSession removeInput:input];
    
    AVCaptureVideoDataOutput *output = (AVCaptureVideoDataOutput*) [captureSession.outputs objectAtIndex:0];
    [captureSession removeOutput:output];
        
    [self.previewLayer removeFromSuperlayer];
    
    self.previewLayer = nil;
    self.captureSession = nil;
#endif
}

- (void)showFlash {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIView *flashView = [[UIView alloc] initWithFrame:frame];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:flashView];
    
    void (^animate)(void) = ^{
        [flashView setAlpha:0.f];
    };
    
    void (^finish)(BOOL finished) = ^(BOOL finished){
        [flashView removeFromSuperview];
        [flashView release];
    };
    
    [UIView animateWithDuration:.4f animations:animate completion:finish];
}

- (void)setActivityView:(BOOL)show {
    MSActivityView *activityIndicator = nil;
    if (show) {
        CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
        CGFloat offsetY = statusFrame.size.height + 44 /* toolbar height in portrait */;
        CGRect frame = CGRectMake(0, offsetY, self.view.frame.size.width, self.view.frame.size.height);
        activityIndicator = [[MSActivityView alloc] initWithFrame:frame];
        activityIndicator.text = @"Searching...";
        activityIndicator.isAnimating = YES;
        activityIndicator.delegate = self;
        // Place this view at the navigation controller level to make sure it ignores tap gestures
        [self.navigationController.view addSubview:activityIndicator];
        [activityIndicator release];
    }
    else {
        for (UIView *v in [self.navigationController.view subviews]) {
            if ([v isKindOfClass:[MSActivityView class]]) {
                activityIndicator = (MSActivityView *) v;
                break;
            }
        }
        [activityIndicator removeFromSuperview];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

#if MS_SDK_REQUIREMENTS
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (_scannerSession.state != MS_SCAN_STATE_DEFAULT) return;
    
    // Convert camera frame
    // --
    MSImage *qry = [[MSImage alloc] initWithBuffer:sampleBuffer orientation:self.orientation];
    
    // Scan
    // --
    NSError *err = nil;
    MSResult *result = [_scannerSession scan:qry options:kMSScanOptions error:&err];
    if (err != nil) {
        NSLog(@" [MOODSTOCKS SDK] SCAN ERROR: %@", [NSString stringWithCString:ms_errmsg([err code])
                                                                       encoding:NSUTF8StringEncoding]);
    }
    
    // Notify the overlay
    // --
    if (result != nil) {
        // We choose to notify only if a *new* result has been found
        if (![_result isEqualToResult:result]) {
            [_result release];
            _result = [result copy];
            
            // This is to prevent the scanner to keep scanning while a result
            // is shown on the overlay side (see `resume` method below)
            [_scannerSession pause];
            
            // Make sure this happens into the *main* thread
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
                [_overlayController scanner:self resultFound:result];
            });
        }
    }
    
    [qry release];
    return;
}
#endif

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    CGRect previewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIView *videoPreviewView = [[[UIView alloc] initWithFrame:previewFrame] autorelease];
    videoPreviewView.tag = 1; /* to identify the video preview view */
    videoPreviewView.backgroundColor = [UIColor blackColor];
    videoPreviewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    videoPreviewView.autoresizesSubviews = YES;
    [self.view addSubview:videoPreviewView];
    
    [_overlayController.view setTag:2];
    [_overlayController.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:_overlayController.view];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(snapAction:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = nil;
    
    [self startCapture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)snapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self showFlash];
    [_scannerSession snap];
}

- (void)dismissAction {
    [self stopCapture];
    // This is to make sure any pending API search is cancelled
    [_scannerSession cancel];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MSScannerDelegate

#if MS_SDK_REQUIREMENTS
- (void)scannerWillSearch:(MSScanner *)scanner {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self setActivityView:YES];
}

- (void)scanner:(MSScanner *)scanner didSearchWithResult:(MSResult *)result {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self setActivityView:NO];
    
    if (result != nil) {
        [_scannerSession pause];
        [_overlayController scanner:self resultFound:result];
    }
    else {
        // Feel free to choose the proper UI component used to warn the user
        // that the API search could not found a match
        [[[[UIAlertView alloc] initWithTitle:@"No match found"
                                     message:nil
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
    }
}

- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self setActivityView:NO];
    
    ms_errcode ecode = [error code];
    // NOTE: ignore negative error codes (e.g. -1 when the request has been cancelled)
    if (ecode >= 0) {
        NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
        
        NSLog(@" [MOODSTOCKS SDK] FAILED TO SEARCH WITH ERROR: %@", errStr);
        
        // Here you may want to inform the user that an error occurred
        // Fee free to adapt to your needs (wording, display policy, etc)
        switch (ecode) {
            case MS_NOCONN:
                errStr = @"No Internet connection.";
                break;
                
            case MS_TIMEOUT:
                errStr = @"The request timed out.";
                break;
                
            default:
                errStr = [NSString stringWithFormat:@"An error occurred (code = %d).", ecode];
                break;
        }
        
        // Feel free to choose the proper UI component to warn the user that an error occurred
        [[[[UIAlertView alloc] initWithTitle:@"Search error"
                                     message:errStr
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
    }
}
#endif

#pragma mark - MSActivityViewDelegate

- (void)activityViewDidCancel:(MSActivityView *)view {
    [_scannerSession cancel];
}

#pragma mark - Public

- (void)resume {
    [_result release];
    _result = nil;
    [_scannerSession resume];
}

@end
