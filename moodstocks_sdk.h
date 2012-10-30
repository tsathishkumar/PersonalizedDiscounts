/**
 * Copyright (C) 2012 Moodstocks. All rights reserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef _MOODSTOCKS_SDK_H
#define _MOODSTOCKS_SDK_H

/** Library version string */
extern const char *ms_version;

/*************************************************
 * Error Codes
 *************************************************/

/** Type of a library error code */
typedef int ms_errcode;

enum {                                /* enumeration for error codes */
  MS_SUCCESS = 0,                     /* success */
  MS_ERROR,                           /* unspecified error */
  MS_MISUSE,                          /* invalid use of the library */
  MS_NOPERM,                          /* access permission denied */
  MS_NOFILE,                          /* file not found */
  MS_BUSY,                            /* database file locked */
  MS_CORRUPT,                         /* database file corrupted */
  MS_EMPTY,                           /* empty database */
  MS_AUTH,                            /* authorization denied */
  MS_NOCONN,                          /* no internet connection */
  MS_TIMEOUT,                         /* operation timeout */
  MS_THREAD,                          /* threading error */
  MS_CREDMISMATCH,                    /* credentials mismatch */
  MS_SLOWCONN,                        /* internet connection too slow */
  MS_NOREC                            /* record not found */
};

/** Get the character string corresponding to an error code.
 * `ecode' specifies the error code.
 * The return value is the character string of the error code.
 */
const char *ms_errmsg(ms_errcode ecode);

/*************************************************
 * Image Data Types
 *************************************************/

/**
 * Pixel Format
 *
 * Specifies the color format and encoding for each pixel in the image.
 *
 * MS_PIX_FMT_RGB32
 * This is a packed-pixel format handled in an endian-specific manner.
 * An RGBA color is packed in one 32-bit integer as follow:
 *   (A << 24) | (R << 16) | (G << 8) | B
 * This is stored as BGRA on little-endian CPU architectures (e.g. iPhone)
 * and ARGB on big-endian CPUs.
 *
 * MS_PIX_FMT_GRAY8
 * This specifies a 8-bit per pixel grayscale pixel format.
 *
 * MS_PIX_FMT_NV21
 * This specifies the YUV pixel format with 1 plane for Y and 1 plane for the
 * UV components, which are interleaved: first byte V and the following byte U
 */
typedef enum {          /* enumeration of pixel formats */
  MS_PIX_FMT_RGB32 = 0, /* 32bpp BGRA on little-endian CPU arch */
  MS_PIX_FMT_GRAY8,     /* 8bpp grey */
  MS_PIX_FMT_NV21,      /* planar YUV 4:2:0, 12bpp, one plane for Y and one for UV */
  MS_PIX_FMT_NB         /* number of pixel formats - do not use! */
} ms_pix_fmt_t;

/**
 * Image Orientation
 *
 * Flags defining the real orientation of the image as found within
 * the EXIF specification
 *
 * Each flag specifies where the origin (0,0) of the image is located.
 * Use 0 (undefined) to ignore or 1 (the default) to keep the
 * image unchanged.
 */
typedef enum {
  /** undefined orientation (i.e image is kept unchanged) */
  MS_UNDEFINED_ORI    = 0,
  /** 0th row is at the top, and 0th column is on the left (the default) */
  MS_TOP_LEFT_ORI     = 1,
  /** 0th row is at the bottom, and 0th column is on the right */
  MS_BOTTOM_RIGHT_ORI = 3,
  /** 0th row is on the right, and 0th column is at the top */
  MS_RIGHT_TOP_ORI    = 6,
  /** 0th row is on the left, and 0th column is at the bottom */
  MS_LEFT_BOTTOM_ORI  = 8
} ms_ori_t;

/** Type of a 8-bit grayscaled image object */
typedef struct ms_img_t_ ms_img_t;

/**
 * Create an image object from input image data.
 * `data' specifies the pointer to aligned image data.
 * `w' specifies the image width in pixels (see below for more details).
 * `h' specifies the image height in pixels (see below for more details).
 * `bpr' specifies the size of aligned image row in bytes.
 * `fmt' specifies the image pixel format.
 * `ori' specifies the image orientation.
 * `img' specifies the pointer to a variable into which the pointer to the created
 * image will be assigned.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * Because the returned image is allocated by this function, it should be released
 * with the `ms_img_del' call when it is no longer useful.
 *
 * IMPORTANT: - the largest input dimension *MUST* be higher than or equal to
 *              480 pixels.
 *            - Image size should not exceed 1280x720 pixels.
 * Any image that does not respect *all* these conditions will be rejected
 * and an `MS_MISUSE` error code will be returned.
 *
 * Whenever possible we recommend you to provide a 1280x720 pixels image.
 */
ms_errcode ms_img_new(const void *data, int w, int h, int bpr, ms_pix_fmt_t fmt,
                      ms_ori_t ori, ms_img_t** img);

/**
 * Delete an image object.
 * `img' specifies the image object.
 */
void ms_img_del(ms_img_t *img);

/*************************************************
 * Barcodes Data Types
 *************************************************/

/** Type of a barcode format */
typedef int ms_barcode_fmt;

enum {                                    /* enumeration for barcode formats */
  MS_BARCODE_FMT_EAN8      = 1 << 0,      /* EAN8 linear barcode */
  MS_BARCODE_FMT_EAN13     = 1 << 1,      /* EAN13 linear barcode */
  MS_BARCODE_FMT_QRCODE    = 1 << 2       /* QR Code 2D barcode */
};

/** Type of a barcode result object */
typedef struct ms_barcode_t_ ms_barcode_t;

/**
 * Get the pointer to the decoded data.
 * `b' specifies the barcode result object.
 * `siz' specifies the pointer to the variable into which the size of the
 * decoded data is assigned.
 * `data' is a pointer to the region containing the decoded data. It should *not*
 * be freed after use. The memory will be freed when ms_barcode_del() will be
 * called on `b';
 */
void ms_barcode_get_data(const ms_barcode_t *b, const char **data, int *siz);

/**
 * Get the format of the decoded data.
 * `b' specifies the barcode result object.
 * The return value is format of the decoded data.
 */
ms_barcode_fmt ms_barcode_get_fmt(const ms_barcode_t *b);

/**
 * Delete a barcode result object.
 * `b' specifies the barcode result object.
 */
void ms_barcode_del(ms_barcode_t *b);

/*************************************************
 * Image Scanner
 *************************************************/

/** Type of a scanner object */
typedef struct ms_scanner_t_ ms_scanner_t;

/**
 * Create a scanner object.
 * `s' specifies the pointer to a variable into which the pointer to the created
 * scanner will be assigned.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 */
ms_errcode ms_scanner_new(ms_scanner_t **s);

/**
 * Delete a scanner object.
 * `s' specifies the scanner object.
 * If the scanner object is not closed, it is done implicitly.
 */
void ms_scanner_del(ms_scanner_t *s);

/**
 * Open a scanner object.
 * `s' specifies the scanner object.
 * `path' specifies the path of the database file to be used by this scanner.
 * `key' specifies the character string containing a valid Moodstocks API key
 * to be used with this scanner.
 * `secret' specifies the character string containing a valid Moodstocks API secret
 * to be used with this scanner.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * If this operation failed it is not possible to use the scanner for any other
 * operation.
 * If you try to open a scanner object that is already opened this function
 * returns an `MS_MISUSE` error code.
 */
ms_errcode ms_scanner_open(ms_scanner_t *s, const char *path,
                           const char *key, const char *secret);

/**
 * Close a scanner object.
 * `s' specifies the scanner object.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * Closing a scanner releases its database file.
 * If you try to close a scanner that is not opened this function returns an
 * `MS_MISUSE` error code.
 */
ms_errcode ms_scanner_close(ms_scanner_t *s);

/**
 * Remove the database file related to a scanner.
 * This is a convenient utility provided for *extraordinary* situations.
 * In practice there are no more than two situtations that legitimate calling clean:
 * - when the `ms_scanner_open` operation failed because of a corrupt database,
 *   i.e. when the `MS_CORRUPT` error code is returned;
 * - when you decide intentionally to clean up the database file, e.g. because
 *   of not enough disk space, etc.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * This function fails with a locking error (error code `MS_BUSY`) if an open
 * scanner is associated to the database file. Make sure to close the scanner
 * object before calling it.
 */
ms_errcode ms_scanner_clean(const char *path);

/*************************************************
 * Offline Search
 *************************************************/

/** Type of a synchronization progress callback function
 * `opq` specifies the pointer to the opaque object that will be passed as input
 * `total` specifies the total number of image signatures to be synchronized
 * `current` specifies how many image signatures have been synchronized so far
 */
typedef void (*ms_scanner_sync_cb)(void *opq, int total, int current);

/**
 * Synchronize a scanner object via HTTP requests to Moodstocks API.
 * This requires a working Internet connection.
 * `s' specifies the scanner object.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned. In particular, if no connection is available, a MS_NOCONN error code
 * will be returned.
 * It is important to note that this function is blocking. It must be run
 * asynchronously to avoid blocking the main thread of the application.
 */
ms_errcode ms_scanner_sync(ms_scanner_t *s);

/** Same as `ms_scanner_sync` with the ability to provide a progress callback
 * This requires a working Internet connection.
 * `s' specifies the scanner object.
 * `cb` specifies the progress callback function
 * `opq` specifies the pointer to the opaque object that will be passed as
 * input to the progress callback function
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned. In particular, if no connection is available, a MS_NOCONN error code
 * will be returned.
 * It is important to note that this function is blocking. It must be run
 * asynchronously to avoid blocking the main thread of the application.
 */
ms_errcode ms_scanner_sync2(ms_scanner_t *s, ms_scanner_sync_cb cb, void *opq);

/**
 * Get information about the synchronized database.
 * This does not require any Internet connection.
 * `s' specifies the scanner object.
 * `count' specifies the pointer to a variable into which the size of the
 * database (i.e. the number of image records) is assigned.
 * `ids' specifies the pointer to a variable into which the pointer to the array
 * of unique image identifier strings are stored.
 * If the array of identifiers is not needed, `NULL' can be specified.
 * If the array is provided, it will contain `count' strings if the database is not empty.
 * Because the returned array and each array element are allocated by this function,
 * they should be released with the `free' call when they are no longer useful.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * If the database contains no image record, this function returns an `MS_EMPTY'
 * error code and does not modify `count' and `ids'.
 */
ms_errcode ms_scanner_info(ms_scanner_t *s, int *count, char ***ids);

/**
 * Perform a search on the synchronized database (aka offline search).
 * This does not require any Internet connection.
 * `s' specifies the scanner object.
 * `qry' specifies the query image object.
 * `id' specifies the pointer to a variable into which the pointer to the result
 * character string representing the image unique identifier will be assigned
 * if a match is found.
 * If there is no match the result is set to `NULL'.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * Because the returned result is allocated by this function when a match is found
 * it should be released with the `free' call when it is no longer useful.
 */
ms_errcode ms_scanner_search(ms_scanner_t *s, const ms_img_t *qry, char **id);

/**
 * Match a query image against a reference image from the synchronized
 * database.
 * This does not require any Internet connection.
 * `s' specifies the scanner object.
 * `qry' specifies the query image object.
 * `id' specifies the character string containing the unique identifier of the
 * reference image to be matched against.
 * `match' specifies the pointer to a variable into which the matching result will
 * be assigned. If query matches against the reference image the value is `1',
 * else it is `0'.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * In particular, if there is no reference image with `id' unique identifier into
 * the database, MS_NOREC error code is returned. If the database is empty then
 * MS_EMPTY is returned.
 */
ms_errcode ms_scanner_match(ms_scanner_t *s, const ms_img_t *qry, const char *id,
                            int *match);

/*************************************************
 * Online Search
 *************************************************/

/**
 * Perform a search via an HTTP request to Moodstocks API.
 * This requires a working Internet connection.
 * `s' specifies the scanner object.
 * `qry' specifies the query image object.
 * `id' specifies the pointer to a variable into which the pointer to the result
 * character string representing the image unique identifier will be assigned
 * if a match is found.
 * If there is no match the result is set to `NULL'.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned. In particular, if no connection is available, a MS_NOCONN error code
 * will be returned.
 * Because the returned result is allocated by this function when a match is found
 * it should be released with the `free' call when it is no longer useful.
 * It is important to note that this function is blocking. It must be run
 * asynchronously to avoid blocking the main thread of the application.
 */
ms_errcode ms_scanner_api_search(ms_scanner_t *s, const ms_img_t *qry, char **id);

/*************************************************
 * Barcode Decoding
 *************************************************/

/**
 * Perform a barcode decoding.
 * `s' specifies the scanner object.
 * `qry' specifies the query image object.
 * `formats' specifies the formats to be decoded. Each format must be added by bitwise-or.
 * `barcode' specifies the pointer to a variable into which the pointer to the result
 * barcode will be assigned if a barcode is successfully decoded. If no barcde
 * is decoded the result is set to `NULL'.
 * If successful, the return value is MS_SUCCESS, otherwise an appropriate error code
 * is returned.
 * Because the returned result is allocated by this function when a barcode is decoded
 * it should be released with the `ms_barcode_del' call when it is no longer useful.
 */
ms_errcode ms_scanner_decode(ms_scanner_t *s, const ms_img_t *qry, int formats,
                             ms_barcode_t **barcode);

#endif
