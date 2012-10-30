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

#import "MSAvailability.h"

#if MS_SDK_REQUIREMENTS
  #import <AVFoundation/AVFoundation.h>
#endif

#include "moodstocks_sdk.h"

#import "MSImage.h"
#import "MSResult.h"

@protocol MSScannerDelegate;

/**
 * Wrapper around Moodstocks SDK scanner object
 *
 * The scanner offers an unified interface to perform:
 * - local database syncronization with offline content,
 * - offline search over the local database of image records,
 * - remote search on Moodstocks API,
 * - 1D/2D barcode decoding.
 */
@interface MSScanner : NSObject {
    NSString *_dbPath;
    ms_scanner_t *_scanner;
    NSOperationQueue *_syncQueue;
    NSMutableArray *_syncDelegates;
    NSOperationQueue *_searchQueue;
}

/**
 * Internal scanner handle
 */
@property (nonatomic, readonly) ms_scanner_t *handle;

/**
 * Array of non-retained objects that receive messages about the current synchronization.
 * This is useful if you need to register *extra* delegate(s) that are supposed to be notified
 * each time a synchronization is triggered such as an UI component, etc
 */
@property (nonatomic, readonly) NSMutableArray *syncDelegates;

/**
 * Obtain the singleton instance
 */
+ (MSScanner *)sharedInstance;

#if MS_SDK_REQUIREMENTS
/**
 * Open the scanner and connect it to the database file
 */
- (BOOL)open:(NSError **)error;

/**
 * Close the scanner and disconnect it from the database file
 */
- (BOOL)close:(NSError **)error;

/**
 * Synchronize the local database with offline content from Moodstocks API
 *
 * This method runs in the background so you can safely call it from the main thread.
 *
 * Take care to implement the ad hoc `MSScannerDelegate` protocol methods since
 * this method keeps its delegate notified.
 *
 * NOTE: this method requires an Internet connection.
 */
- (void)syncWithDelegate:(id<MSScannerDelegate>)delegate;

/**
 * Check if a sync is pending
 */
- (BOOL)isSyncing;

/**
 * Get the total number of images recorded into the local database
 */
- (NSInteger)count:(NSError **)error;

/**
 * Get an array made of all images identifiers found into the local database
 */
- (NSArray *)info:(NSError **)error;

/**
 * Perform a remote image search on Moodstocks API
 *
 * This method runs in the background so you can safely call it from the main thread.
 *
 * Take care to implement the ad hoc `MSScannerDelegate` protocol methods since
 * this method keeps its delegate notified.
 *
 * NOTE: this method requires an Internet connection.
 */
- (void)apiSearch:(MSImage *)qry withDelegate:(id<MSScannerDelegate>)delegate;

/**
 * Cancel any pending API search(es)
 */
- (void)cancelApiSearch;

/**
 * Performs an offline image search among the local database
 */
- (MSResult *)search:(MSImage *)qry error:(NSError **)error;

/**
 * Matches a query image against a local database reference
 */
- (BOOL)match:(MSImage *)qry uid:(NSString *)uid error:(NSError **)error;

/**
 * Performs barcode decoding on the query image, among given formats
 */
- (MSResult *)decode:(MSImage *)qry formats:(int)formats error:(NSError **)error;

#endif

@end

/**
 * Scanner protocol for asynchronous network operations
 *
 * NOTE: these methods are always called on main thread
 */
@protocol MSScannerDelegate <NSObject>
@optional
/**
 * Dispatched when a synchronization is about to start
 */
- (void)scannerWillSync:(MSScanner *)scanner;

/**
 * Dispatched as soon as the synchronization progresses
 *
 * current specifies how many image signatures have been fetched so far
 *
 * total specifies the total number of images signatures that have to be fetched
 */
- (void)didSyncWithProgress:(NSNumber *)current total:(NSNumber *)total;

/**
 * Dispatched when a synchronization is completed
 */
- (void)scannerDidSync:(MSScanner *)scanner;

/**
 * Dispatched when a synchronization failed
 */
- (void)scanner:(MSScanner *)scanner failedToSyncWithError:(NSError *)error;

/**
 * Dispatched when a synchronization is about to start an API search
 */
- (void)scannerWillSearch:(MSScanner *)scanner;

/**
 * Dispatched when an online search (aka API search) is completed
 *
 * NOTE: the returned result is `nil` in case of no match found
 */
- (void)scanner:(MSScanner *)scanner didSearchWithResult:(MSResult *)result;

/**
 * Dispatched when an online search (aka API search) failed
 */
- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error;
@end
