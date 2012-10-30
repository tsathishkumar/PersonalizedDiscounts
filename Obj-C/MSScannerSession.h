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

#import <Foundation/Foundation.h>

#import "MSScanner.h"
#import "MSImage.h"
#import "MSResult.h"
#import "MSObjC.h"

/** Current scanner session state */
typedef enum {
    MS_SCAN_STATE_DEFAULT = 0,
    MS_SCAN_STATE_SEARCH,
    MS_SCAN_STATE_PAUSE
} MSScanState;

@interface MSScannerSession : NSObject
#if MS_SDK_REQUIREMENTS
<MSScannerDelegate>
#endif
{
    MSResult *_result;
    int _losts;
    MSScanner *_scanner;
    BOOL _snap;
    MSScanState _state;
#if __has_feature(objc_arc_weak)
    id<MSScannerDelegate> __weak _delegate;
#elif __has_feature(objc_arc)
    id<MSScannerDelegate> __unsafe_unretained _delegate;
#else
    id<MSScannerDelegate> _delegate;
#endif
}

#if __has_feature(objc_arc_weak)
@property (nonatomic, weak) id<MSScannerDelegate> delegate;
#elif __has_feature(objc_arc)
@property (nonatomic, unsafe_unretained) id<MSScannerDelegate> delegate;
#else
@property (nonatomic, assign) id<MSScannerDelegate> delegate;
#endif
@property (nonatomic, readonly) MSScanState state;

/**
 * Create a new scanner session.
 *
 * You should create a new MSScannerSession each time a scanner is
 * presented to the user.
 */
- (id)initWithScanner:(MSScanner *)scanner;

/**
 * Pause scanning
 *
 * This has for effect to ignore any subsequent scan / snap calls until resume
 * is called.
 *
 * Returns YES if the scanner session has been paused, NO otherwise.
 *
 * One cannot pause the scanner session if an API search is pending. You must first
 * call the `cancel` method.
 */
- (BOOL)pause;

/**
 * Resume scanning
 *
 * This has for effect to start processing again any subsequent scan / snap calls
 *
 * Returns YES if the scanner session has been resumed, NO otherwise.
 */
- (BOOL)resume;

/**
 * Scan the input image
 *
 * Scanning performs a *simultaneous* run of offline search and barcode decoding
 * according to the options supplied. The input options must be a list of
 * bitwise-or separated flags chosen among `MSResultType` (see MSResult.h)
 *
 * NOTE: this method fully operates on the client-side without any remote call
 *
 * e.g. if you choose to perform offline image recognition and QR-Code decoding:
 *
 * int options = MS_RESULT_TYPE_IMAGE | MS_RESULT_TYPE_QRCODE;
 */
- (MSResult *)scan:(MSImage *)qry options:(int)options error:(NSError **)error;

/**
 * Snap the next incoming query frame and perform an API search with it
 *
 * The scanner session delegate will be notified of the API search life-cycle via
 * the `MSScannerDelegate` protocol
 *
 * NOTE: this method will trigger an API search and thus requires an Internet
 *       connection
 *
 * Returns YES if the snap has correctly been deferred, NO otherwise (e.g. you
 * cannot defer a snap when the scanner session is paused)
 */
- (BOOL)snap;

/**
 * Cancel any pending API search triggered by `snap`
 *
 * Returns YES if the cancelling has been applied, NO otherwise.
 */
- (BOOL)cancel;

@end
