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

#import "MSScannerSession.h"

@interface MSScannerSession ()

- (void)reset;

@end

@implementation MSScannerSession

@synthesize delegate = _delegate;
@synthesize state = _state;

- (id)initWithScanner:(MSScanner *)scanner {
    self = [super init];
    if (self) {
        _result = nil;
        _losts = 0;
        _snap = NO;
        _state = MS_SCAN_STATE_DEFAULT;
        _scanner = scanner;
        _delegate = nil;
    }
    return self;
}

- (void)dealloc {
    [_result release_stub];
    _result = nil;

    _delegate = nil;

#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)reset {
    [_result release_stub];
    _result = nil;
    _losts = 0;
    _snap = NO;
}

- (BOOL)pause {
    if (_state != MS_SCAN_STATE_DEFAULT) return FALSE;
    _state = MS_SCAN_STATE_PAUSE;
    return YES;
}

- (BOOL)resume {
    if (_state != MS_SCAN_STATE_PAUSE) return FALSE;
    [self reset];
    _state = MS_SCAN_STATE_DEFAULT;
    return YES;
}


- (MSResult *)scan:(MSImage *)qry options:(int)options error:(NSError **)error {
    MSResult *result = nil;
#if MS_SDK_REQUIREMENTS
    if (_state != MS_SCAN_STATE_DEFAULT) return nil;

    if (_snap) {
        _snap = NO;
        _state = MS_SCAN_STATE_SEARCH;
        [[MSScanner sharedInstance] apiSearch:qry withDelegate:self];
        return nil;
    }

    BOOL lock = NO;
    if (_result != nil && _losts < 2) {
        int _resultType = [_result getType];
        NSInteger found = 0;
        if (_resultType == MS_RESULT_TYPE_IMAGE) {
            found = [_scanner match:qry uid:[_result getValue] error:nil] ? 1 : -1;
        }
        else if (_resultType == MS_RESULT_TYPE_QRCODE) {
            MSResult *barcode = [_scanner decode:qry formats:MS_RESULT_TYPE_QRCODE error:nil];
            found = [barcode isEqualToResult:_result] ? 1 : -1;
        }

        if (found == 1) {
            // The current frame matches with the previous result
            lock = YES;
            _losts = 0;
        }
        else if (found == -1) {
            // The current frame looks different so release the lock
            // if there is enough consecutive "no match"
            _losts++;
            lock = (_losts >= 2) ? NO : YES;
        }
    }

    if (lock) {
        // Re-use the previous result and skip searching / decoding
        // the current frame
        result = [[_result copy] autorelease_stub];
    }

    // -------------------------------------------------
    // Image search
    // -------------------------------------------------
    if (result == nil && (options & MS_RESULT_TYPE_IMAGE)) {
        NSError *err  = nil;
        result = [_scanner search:qry error:&err];
        if (err != nil && [err code] != MS_EMPTY) {
            if (error) *error = err;
            return nil;
        }
        if (result != nil) {
            _losts = 0;
        }
    }

    // -------------------------------------------------
    // Barcode decoding
    // -------------------------------------------------
    if (result == nil) {
        NSError *err  = nil;
        result = [_scanner decode:qry formats:options error:&err];
        if (err != nil) {
            if (error) *error = err;
            return nil;
        }
        if (result != nil) {
            _losts = 0;
        }
    }

    if (![result isEqualToResult:_result]) {
        [_result release_stub];
        _result = [result copy];
    }

#endif
    return result;
}

- (BOOL)snap {
    if (_state != MS_SCAN_STATE_DEFAULT) return FALSE;
    _snap = YES;
    return YES;
}

- (BOOL)cancel {
    if (_state != MS_SCAN_STATE_SEARCH) return FALSE;
#if MS_SDK_REQUIREMENTS
    [_scanner cancelApiSearch];
#endif
    return YES;
}

#pragma mark - MSScannerDelegate

- (void)scannerWillSearch:(MSScanner *)scanner {
    [self reset];

    if ([_delegate respondsToSelector:@selector(scannerWillSearch:)]) {
        [_delegate scannerWillSearch:_scanner];
    }
}

- (void)scanner:(MSScanner *)scanner didSearchWithResult:(MSResult *)result {
    _state = MS_SCAN_STATE_DEFAULT;

    if ([_delegate respondsToSelector:@selector(scanner:didSearchWithResult:)]) {
        [_delegate scanner:_scanner didSearchWithResult:result];
    }
}

- (void)scanner:(MSScanner *)scanner failedToSearchWithError:(NSError *)error {
    _state = MS_SCAN_STATE_DEFAULT;

    if ([_delegate respondsToSelector:@selector(scanner:failedToSearchWithError:)]) {
        [_delegate scanner:_scanner failedToSearchWithError:error];
    }
}

@end
