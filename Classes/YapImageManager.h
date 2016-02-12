//
//  YapImageManager.h
//  Feedworthy
//
//  Created by Trevor Stout on 11/8/13.
//  Copyright (c) 2013 Yap Studios LLC. All rights reserved.
//

#import "YapImageSessionManager.h"

#define MAX_SIMULTANEOUS_IMAGE_REQUESTS 5
#define MAX_SIMULTANEOUS_MOVIE_REQUESTS 3

extern NSString *const YapImageManagerUpdatedNotification;
extern NSString *const YapImageManagerFailedNotification;
extern NSString *const YapImageManagerImageAttributesUpdatedNotification;
extern NSString *const YapImageManagerMovieUpdatedNotification;
extern NSString *const YapImageManagerMovieFailedNotification;
extern NSString *const YapImageManagerMovieFilenameKey;
extern NSString *const YapImageManagerURLKey;
extern NSString *const YapImageManagerImageAttributesKey;
extern NSString *const YapImageManagerImageWillBeginDownloadingNotification;
extern NSString *const YapImageManagerMovieWillBeginDownloadingNotification;

@interface YapImageManager : NSObject <UIWebViewDelegate, YapImageSessionManagerDelegate>

// images
- (void)imageForURLString:(NSString *)URLString completion:(void(^)(UIImage *image, NSString *URLString))completion; // full sized image
- (void)imageForURLString:(NSString *)URLString size:(CGSize)size completion:(void(^)(UIImage *image, NSString *URLString))completion; // resized image
- (void)queueImageForURLString:(NSString *)URLString;
- (void)queueImageForURLString:(NSString *)URLString size:(CGSize)size;
- (void)backgroundQueueImageForURLString:(NSString *)URLString;
- (void)backgroundQueueImageForURLString:(NSString *)URLString size:(CGSize)size;
- (BOOL)isImageQueuedForURLString:(NSString *)URLString;
- (void)prioritizeImageForURLString:(NSString *)URLString;

// these methods are synchronous, so not recommened for use during scrolling
- (UIImage *)cachedImageForURLString:(NSString *)URLString; // full sized image
- (UIImage *)cachedImageForURLString:(NSString *)URLString size:(CGSize)size; // resized image
- (NSData *)imageDataForURLString:(NSString *)URLString;

// image attributes
- (NSDictionary *)imageAttributesForURLString:(NSString *)URLString;
- (CGSize)imageSizeForImageWithAttributes:(NSDictionary *)imageAttributes;

// animated GIF support
- (void)movieForURLString:(NSString *)URLString completion:(void(^)(NSString *movieFilename, NSString *URLString))completion;
- (void)movieForURLString:(NSString *)URLString gfycatId:(NSString *)gfycatId isImgurGifv:(BOOL)isImgurGifv completion:(void(^)(NSString *movieFilename, NSString *URLString))completion;
- (NSData *)movieDataForURLString:(NSString *)URLString movieFileName:(NSString **)movieFilename;

// helper methods
- (UIImage *)imageWithAspectFillCPU:(UIImage *)image size:(CGSize)size;

// progress
- (NSProgress *)downloadProgressForURLString:(NSString *)URLString;
- (NSProgress *)movieProgressForURLString:(NSString *)URLString;

+ (YapImageManager *)sharedInstance;

// private
- (void)saveImage:(NSData *)imageData forURLString:(NSString *)URLString;

@end
