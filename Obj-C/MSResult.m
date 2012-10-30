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

#import "MSResult.h"
#import "MSObjC.h"

@implementation MSResult

@synthesize type = _type;
@synthesize length = _length;
@synthesize bytes = _bytes;

- (id)init {
    self = [super init];
    if (self) {
        _type = MS_RESULT_TYPE_NONE;
        _length = -1;
        _bytes = NULL;
    }
    return self;
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length type:(int)type {
    self = [self init];
    if (self) {
        _type = type;
        _length = length;
        if (bytes) {
            _bytes = malloc(length + 1);
            memcpy(_bytes, bytes, length);
            _bytes[length] = '\0';
        }
    }
    return self;
}

- (id)initWithBarcode:(const ms_barcode_t *)barcode {
#if MS_SDK_REQUIREMENTS
    int length;
    const char *bytes;
    ms_barcode_get_data(barcode, &bytes, &length);
    self = [self initWithBytes:bytes length:length type:ms_barcode_get_fmt(barcode)];
#else
    self = [self init];
#endif
    return self;
}

- (id)initWithImageID:(const char *)uid {
    return [self initWithBytes:uid length:strlen(uid) type:MS_RESULT_TYPE_IMAGE];
}

- (NSString *)getValue {
    NSString *str = nil;
    if (_bytes) {
        str = [[[NSString alloc] initWithBytes:_bytes
                                        length:_length
                                      encoding:NSUTF8StringEncoding] autorelease_stub];
    }
    return str;
}

- (NSData *)getData {
    return [[[NSData alloc] initWithBytes:_bytes length:_length] autorelease_stub];
}

- (int)getType {
    return _type;
}

- (BOOL)isEqualToResult:(MSResult *)result {
    if (_type != [result type] || _length != [result length] || memcmp(_bytes, [result bytes], _length))
        return NO;
    return YES;
}

- (void)dealloc {
    if (_bytes) free(_bytes);
    _bytes = NULL;

#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (id)copyWithZone:(NSZone *)zone {
    return [[MSResult allocWithZone:zone] initWithBytes:_bytes
                                                 length:_length
                                                   type:_type];
}

@end
