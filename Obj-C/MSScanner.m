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

#import "MSScanner.h"
#import "MSDebug.h"
#import "MSSync.h"
#import "MSApiSearch.h"
#import "MSObjC.h"

// Callbacks to create a non retaining array
static const void *MSScannerRetainNoOp(CFAllocatorRef allocator, const void *value) { return value; }
static void MSScannerNoOp(CFAllocatorRef allocator, const void *value) { }

static MSScanner *gMSScanner   = nil;
static NSString *kMSDBFilename = @"ms.db";

// -------------------------------------------------
// Moodstocks API key/secret pair
// -------------------------------------------------
static NSString *kMSAPIKey     = @"9kYxSDgOhWoMLoV8RlbZ";
static NSString *kMSAPISecret  = @"no1E8LOeJJUbK65m";

// Flag to control the scanner behavior when the app switches between
// foreground and background
//
// Set to 1 (recommended) to keep the scanner opened when the app enters background.
// This consumes some memory, but avoids CPU overhead when the app is switched
// back into the foreground
#define MSSCANNER_KEEP_OPENED 1

@interface MSScanner ()

#if MS_SDK_REQUIREMENTS
- (void)applicationWillLeaveForeground:(void *)ignored;
- (void)applicationWillEnterForeground:(void *)ignored;
#endif

@end

@implementation MSScanner

@synthesize handle = _scanner;
@synthesize syncDelegates = _syncDelegates;

+ (MSScanner *)sharedInstance {
    if (!gMSScanner) {
        gMSScanner = [[MSScanner alloc] init];
    }
    return gMSScanner;
}

- (id)init {
    self = [super init];
    if (self) {
        _scanner = NULL;

#if MS_SDK_REQUIREMENTS

        // Instantiate the internal scanner object
        ms_errcode ecode = ms_scanner_new(&_scanner);
        if (ecode != MS_SUCCESS) {
            // Fatal error
            NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
            NSString *reasonStr = [NSString stringWithFormat:@"Can't allocate a scanner object: %@", errStr];
            [[NSException exceptionWithName:@"MSScannerException" 
                                     reason:reasonStr
                                   userInfo:nil] raise];
        }
        
        // Build database path for later use
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesPath = [paths objectAtIndex:0];
        _dbPath = [[cachesPath stringByAppendingPathComponent:kMSDBFilename] retain_stub];
        
        // Register to application lifecycle notifications
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(applicationWillLeaveForeground:)
                       name:UIApplicationWillTerminateNotification
                     object:nil];

#if !MSSCANNER_KEEP_OPENED
        [center addObserver:self
                   selector:@selector(applicationWillLeaveForeground:)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationWillEnterForeground:)
                       name: UIApplicationWillEnterForegroundNotification
                     object:nil];
#endif

#endif        
        _syncQueue = [[NSOperationQueue alloc] init];
        CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
        callbacks.retain = MSScannerRetainNoOp;
        callbacks.release = MSScannerNoOp;
#if __has_feature(objc_arc)
        _syncDelegates = (NSMutableArray *) CFBridgingRelease(CFArrayCreateMutable(nil, 0, &callbacks));
#else
        _syncDelegates = (NSMutableArray *) CFArrayCreateMutable(nil, 0, &callbacks);
#endif
        _searchQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

#if MS_SDK_REQUIREMENTS
    if (_scanner) ms_scanner_del(_scanner);
#endif
    _scanner = NULL;
    
    [_dbPath release_stub];
    _dbPath = nil;
    
    [_syncQueue release_stub];
    _syncQueue = nil;
    
    [_syncDelegates release_stub];
    _syncDelegates = nil;
    
    [_searchQueue release_stub];
    _searchQueue = nil;
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark - Public

#if MS_SDK_REQUIREMENTS
- (BOOL)open:(NSError **)error {
    BOOL err = NO;
    
    if (MSDeviceCompatibleWithSDK()) {
        ms_errcode ecode = ms_scanner_open(_scanner,
                                           [_dbPath UTF8String],
                                           [kMSAPIKey UTF8String],
                                           [kMSAPISecret UTF8String]);

        if (ecode == MS_CORRUPT) {
            ms_scanner_close(_scanner);
            ms_scanner_clean([_dbPath UTF8String]);
            ecode = ms_scanner_open(_scanner,
                                    [_dbPath UTF8String],
                                    [kMSAPIKey UTF8String],
                                    [kMSAPISecret UTF8String]);
        }

        if (ecode != MS_SUCCESS) {
            err = YES;
            if (error != nil) {
                *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
            }
        }
    }
    else {
        err = YES;
        if (error != nil) {
            *error = [NSError errorWithDomain:@"moodstocks-sdk" code:0xbadef1ce /* bad device */ userInfo:nil];
        }
    }
    
    return !err;
}

- (BOOL)close:(NSError **)error {
    BOOL err = NO;
    
    ms_errcode ecode = ms_scanner_close(_scanner);
    if (ecode != MS_SUCCESS) {
        err = YES;
        if (error != nil) {
            *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
        }
    }
    
    return !err;
}

- (void)syncWithDelegate:(id<MSScannerDelegate>)delegate {
    MSSync *op = [[[MSSync alloc] initWithScanner:self] autorelease_stub];
    [op setDelegate:delegate];
    [_syncQueue addOperation:op];
}

- (BOOL)isSyncing {
    return !!([_syncQueue operationCount] >= 1);
}

- (NSInteger)count:(NSError **)error {
    int cnt;
    ms_errcode ecode = ms_scanner_info(_scanner, &cnt, NULL);
    if (ecode != MS_SUCCESS && ecode != MS_EMPTY) {
        cnt = -1;
        if (error != nil) {
            *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
        }
    }
    else if (ecode == MS_EMPTY)
        cnt = 0;
    
    return (NSInteger) cnt;
}

- (NSArray *)info:(NSError **)error {
    NSMutableArray *ary = [NSMutableArray arrayWithCapacity:[self count:nil]];
    int cnt;
    char **ids = NULL;
    ms_errcode ecode = ms_scanner_info(_scanner, &cnt, &ids);
    if (ecode != MS_SUCCESS && ecode != MS_EMPTY) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
        }
    }
    else if (ids != NULL) {
        for (int i = 0; i < cnt; i++) {
            [ary addObject:[NSString stringWithCString:ids[i] encoding:NSUTF8StringEncoding]];
        }
    }
    
    if (ids != NULL) free(ids);
    
    return ary;
}


- (MSResult *)search:(MSImage *)qry error:(NSError **)error {
    MSResult *result = nil;

    char *uid = NULL;
    ms_errcode ecode = ms_scanner_search(_scanner, [qry image], &uid);
    if (ecode == MS_SUCCESS) {
        if (uid != NULL) {
            result = [[[MSResult alloc] initWithImageID:uid] autorelease_stub];
            free(uid);
        }
    }
    else if (error) {
        *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
    }
    
    return result;
}

- (BOOL)match:(MSImage *)qry uid:(NSString *)uid error:(NSError **)error {
    BOOL match = NO;
    
    int m;
    ms_errcode ecode = ms_scanner_match(_scanner, [qry image], [uid UTF8String], &m);
    if (ecode == MS_SUCCESS) {
        match = (m == 1) ? YES : NO;
    }
    else if (error) {
        *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
    }
    
    return match;
}

- (void)apiSearch:(MSImage *)qry withDelegate:(id<MSScannerDelegate>)delegate {
    MSApiSearch *op = [[[MSApiSearch alloc] initWithScanner:self query:qry] autorelease_stub];
    [op setDelegate:delegate];
    [_searchQueue addOperation:op];
}

- (void)cancelApiSearch {
    [_searchQueue cancelAllOperations];
}

- (MSResult *)decode:(MSImage *)qry formats:(int)formats error:(NSError **)error {
    MSResult *result = nil;

    ms_barcode_t *barcode = NULL;
    ms_errcode ecode = ms_scanner_decode(_scanner, [qry image], formats, &barcode);
    if (ecode == MS_SUCCESS) {
        if (barcode != NULL) {
            result = [[[MSResult alloc] initWithBarcode:barcode] autorelease_stub];
            ms_barcode_del(barcode);
        }
    }
    else if (error) {
        *error = [NSError errorWithDomain:@"moodstocks-sdk" code:ecode userInfo:nil];
    }
    
    return result;
}
#endif

#pragma mark - NSNotifications

#if MS_SDK_REQUIREMENTS
- (void)applicationWillLeaveForeground:(void *)ignored {
    NSError *err;
    if (![self close:&err]) {
        ms_errcode ecode = [err code];
        NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
        MSDLog(@" [APP EXIT] SCANNER CLOSE ERROR: %@", errStr);
    }
}

- (void)applicationWillEnterForeground:(void *)ignored {
    NSError *err;
    if (![self open:&err]) {
        ms_errcode ecode = [err code];
        NSString *errStr = [NSString stringWithCString:ms_errmsg(ecode) encoding:NSUTF8StringEncoding];
        MSDLog(@" [APP ENTER] SCANNER OPEN ERROR: %@", errStr);
    }
}
#endif

@end
