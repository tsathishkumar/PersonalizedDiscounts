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

#include "moodstocks_sdk.h"

#import "MSSync.h"
#import "MSObjC.h"

@interface MSSyncProgress : NSObject

- (id)initWithCurrent:(int)c total:(int)t;

@property (nonatomic, assign) int current;
@property (nonatomic, assign) int total;

@end

@implementation MSSyncProgress

@synthesize current;
@synthesize total;

- (id)initWithCurrent:(int)c total:(int)t {
    self = [super init];
    if (self) {
        self.current = c;
        self.total = t;
    }
    return self;
}

@end

@interface MSSync ()
- (void)willSync;
- (void)didSyncWithProgress:(MSSyncProgress *)progress;
- (void)didSync;
- (void)failedToSyncWithError:(NSError *)error;
@end

static void mssync_progress_cb(void *opq, int total, int current) {
    // Do not change: this is to make sure we won't block the sync
    BOOL wait = NO;
    MSSyncProgress *progress = [[[MSSyncProgress alloc] initWithCurrent:current
                                                                  total:total] autorelease_stub];
#if __has_feature(objc_arc)
    MSSync *syncOp = (__bridge MSSync *) opq;
#else
    MSSync *syncOp = (MSSync *) opq;
#endif
    [syncOp performSelectorOnMainThread:@selector(didSyncWithProgress:)
                             withObject:progress
                          waitUntilDone:wait];
}

@implementation MSSync

@synthesize delegate = _delegate;

- (id)initWithScanner:(MSScanner *)scanner {
    self = [super init];
    if (self) {
        _scanner = scanner;
        _delegate = nil;
        
    }
    return self;
}

- (void)dealloc {
    _scanner = nil;
    _delegate = nil;
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)cancel {
    NSError *error = [NSError errorWithDomain:@"moodstocks-sdk" code:-1 /* cancel error */ userInfo:nil];
    [self performSelectorOnMainThread:@selector(failedToSyncWithError:) withObject:error waitUntilDone:YES];

    [super cancel];
}

- (void)main {
#if __has_feature(objc_arc)
    @autoreleasepool {
#else
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
#endif
    
#if MS_SDK_REQUIREMENTS
    _taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_taskID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_taskID];
                _taskID = UIBackgroundTaskInvalid;
                [self cancel];
            }
        });
    }];
    
    NSError *error = nil;
    
    if (![self isCancelled]) {
        [self performSelectorOnMainThread:@selector(willSync) withObject:nil waitUntilDone:YES];
        
#if __has_feature(objc_arc)
        void *opq = (__bridge void *) self;
#else
        void *opq = (void *) self;
#endif
        
        ms_errcode ecode = ms_scanner_sync2([_scanner handle], mssync_progress_cb, opq);
        if (ecode != MS_SUCCESS) {
            error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
        }
    }
    
    if (![self isCancelled]) {
        if (!error) {
            [self performSelectorOnMainThread:@selector(didSync) withObject:nil waitUntilDone:YES];
        }
        else {
            [self performSelectorOnMainThread:@selector(failedToSyncWithError:) withObject:error waitUntilDone:YES];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_taskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_taskID];
            _taskID = UIBackgroundTaskInvalid;
        }
    });
#endif

#if __has_feature(objc_arc)
    } /* end of @autoreleasepool block */
#else
    [pool release];
#endif
}

#pragma mark - Private

// NOTE: these methods take care to notify the extra-delegates (if any) held by the scanner

- (void)willSync {
    if ([_delegate respondsToSelector:@selector(scannerWillSync:)])
        [_delegate performSelector:@selector(scannerWillSync:) withObject:_scanner];
    
    for (id<MSScannerDelegate> extra in [_scanner syncDelegates]) {
        if ([extra respondsToSelector:@selector(scannerWillSync:)] && extra != _delegate)
            [extra performSelector:@selector(scannerWillSync:) withObject:_scanner];
    }
}

- (void)didSyncWithProgress:(MSSyncProgress *)progress {
    if ([_delegate respondsToSelector:@selector(didSyncWithProgress:total:)])
        [_delegate performSelector:@selector(didSyncWithProgress:total:)
                        withObject:[NSNumber numberWithInt:progress.current]
                        withObject:[NSNumber numberWithInt:progress.total]];
    
    for (id<MSScannerDelegate> extra in [_scanner syncDelegates]) {
        if ([extra respondsToSelector:@selector(didSyncWithProgress:total:)] && extra != _delegate)
            [extra performSelector:@selector(didSyncWithProgress:total:)
                        withObject:[NSNumber numberWithInt:progress.current]
                        withObject:[NSNumber numberWithInt:progress.total]];
    }
}

- (void)didSync {
    if ([_delegate respondsToSelector:@selector(scannerDidSync:)])
        [_delegate performSelector:@selector(scannerDidSync:) withObject:_scanner];
    
    for (id<MSScannerDelegate> extra in [_scanner syncDelegates]) {
        if ([extra respondsToSelector:@selector(scannerDidSync:)] && extra != _delegate)
            [extra performSelector:@selector(scannerDidSync:) withObject:_scanner];
    }
}

- (void)failedToSyncWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(scanner:failedToSyncWithError:)])
        [_delegate performSelector:@selector(scanner:failedToSyncWithError:)
                        withObject:_scanner
                        withObject:error];
    
    for (id<MSScannerDelegate> extra in [_scanner syncDelegates]) {
        if ([extra respondsToSelector:@selector(scanner:failedToSyncWithError:)] && extra != _delegate)
            [extra performSelector:@selector(scanner:failedToSyncWithError:)
                        withObject:_scanner
                        withObject:error];
    }
}

@end
