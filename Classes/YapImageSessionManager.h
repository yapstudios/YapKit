//
//  YapHTTPImageSessionManager.h
//  Feedworthy
//
//  Created by Trevor Stout on 12/9/13.
//  Copyright (c) 2013 Yap Studios LLC. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>

/** 
 * YapHTTPImageSessionManager, a subclass of AFHTTPSessionManager, attempts to capture the image attributes for JPEG, GIF, and PNG downloads during the download stream.
 * This is useful in cases where you need the image dimentions as soon as possible to layout the UI, for example in a variable height table cell.
**/

@protocol YapImageSessionManagerDelegate;

@interface YapImageSessionManager : AFHTTPSessionManager

@property (nonatomic, weak) id <YapImageSessionManagerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldPreloadImageAttributes;
@property (nonatomic, assign) BOOL shouldPreloadGIFImageData;

- (NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task;

@end

@protocol YapImageSessionManagerDelegate <NSObject>

@optional

// returns the image attributes, if available, decoded in realtime from the download stream
- (void)imageSessionManager:(YapImageSessionManager *)sessionManager imageAttributesFound:(NSDictionary *)imageAttributes forURLString:(NSString *)URLString;

// returns the first frame of a GIF image, if available, decoded in realtime from the download stream
- (void)imageSessionManager:(YapImageSessionManager *)sessionManager GIFImageDataFound:(NSData *)imageData forURLString:(NSString *)URLString shouldCancelRequest:(BOOL *)shouldCancelRequest;

@end