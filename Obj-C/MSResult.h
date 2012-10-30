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

#import "MSAvailability.h"

#include "moodstocks_sdk.h"

/**
 * Scanning types
 * These are to be used either as scan options (see `MSScannerSession`)
 * by combining them with bitwise-or, or to hold a kind of result
 */
typedef enum {
  MS_RESULT_TYPE_NONE      = 0,
  MS_RESULT_TYPE_EAN8      = 1 << 0,      /* EAN8 linear barcode */
  MS_RESULT_TYPE_EAN13     = 1 << 1,      /* EAN13 linear barcode */
  MS_RESULT_TYPE_QRCODE    = 1 << 2,      /* QR Code 2D barcode */
  MS_RESULT_TYPE_IMAGE     = 1 << 31      /* Image */
} MSResultType;

/**
 * Structure holding the result of a scan
 * It is composed of:
 * - its type among those listed in `MSResultType` enum above
 * - its value as a string that may represent:
 *  - an image ID when the type is `MS_RESULT_TYPE_IMAGE`,
 *  - a barcode numbers when the type is `MS_RESULT_TYPE_EAN8`
 *    or `MS_RESULT_TYPE_EAN13`
 *  - raw QR Code data (i.e. *unparsed*) when type is `MS_RESULT_TYPE_QRCODE`
 */
@interface MSResult : NSObject <NSCopying> {
    int _type;
    int _length;
    char *_bytes;
}

@property (nonatomic, readonly) int type;
@property (nonatomic, readonly) int length;
@property (nonatomic, readonly) char *bytes;

- (id)init;
- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length type:(int)type;
- (id)initWithBarcode:(const ms_barcode_t *)barcode;
- (id)initWithImageID:(const char *)uid;

/**
 * Return the result as a string with UTF-8 encoding
 * Use `getData` if you intend to create a string with another
 * encoding or just want to interact with the raw bytes
 */
- (NSString *)getValue;

/**
 * Return the result as raw data (byte array)
 */
- (NSData *)getData;

/**
 * Return the result type
 */
- (int)getType;

/**
 * Return YES if the current result is strictly the same than
 * the input one, NO otherwise
 */
- (BOOL)isEqualToResult:(MSResult *)result;

/**
 * Clone this result
 */
- (id)copyWithZone:(NSZone *)zone;
@end
