//
//  YapImageManager.m
//  Feedworthy
//
//  Created by Trevor Stout on 11/8/13.
//  Copyright (c) 2013 Yap Studios LLC. All rights reserved.
//

#import "YapImageManager.h"
#import "YapDatabase.h"
#import "AFNetworking.h"
#import "UIImage+Yap.h"

#import <ImageIO/ImageIO.h>

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NSString+Yap.h"

#import "AFURLRequestSerialization.h"
#import "AFURLSessionManager.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

#define EXPIRE_MP4_INTERVAL              (24 * 60 * 60) // 24 hours
#define EXPIRE_IMAGE_INTERVAL            (24 * 60 * 60) // 24 hours
#define EXPIRE_IMAGE_ATTRIBUTES_INTERVAL 1209600.0      // 14 days

NSString *const YapImageManagerUpdatedNotification = @"YapImageManagerUpdatedNotification";
NSString *const YapImageManagerFailedNotification = @"YapImageManagerFailedNotification";
NSString *const YapImageManagerImageWillBeginDownloadingNotification = @"YapImageManagerImageWillBeginDownloadingNotification";
NSString *const YapImageManagerMovieWillBeginDownloadingNotification = @"YapImageManagerMovieWillBeginDownloadingNotification";
NSString *const YapImageManagerImageAttributesUpdatedNotification = @"YapImageManagerImageAttributesUpdatedNotification";
NSString *const YapImageManagerMovieUpdatedNotification = @"YapImageManagerMovieUpdatedNotification";
NSString *const YapImageManagerMovieFailedNotification = @"YapImageManagerMovieFailedNotification";
NSString *const YapImageManagerMovieFilenameKey = @"movie_filename";
NSString *const YapImageManagerURLKey = @"image_url";
NSString *const YapImageManagerImageAttributesKey = @"image_attributes";

NSString *const kYapImageManagerImageCollection = @"images";
NSString *const kYapImageManagerImageAttributesCollection = @"image_attributes";


#define TARGET_MEDIA_TIMESCALE 60

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = DDLogLevelVerbose;
#else
static const int ddLogLevel = DDLogLevelVerbose;
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - ImageQueueItem
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface ImageQueueItem : NSObject

@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) NSDate *downloadstartTime; // start of download

@end

@implementation ImageQueueItem

- (NSString *)description
{
    return [self URLString];
}

@end

@interface MovieQueueItem : NSObject

@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSString *gfycatId;
@property (nonatomic, assign) BOOL isImgurGifv;
@property (nonatomic, strong) NSString *movieURLString;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) NSDate *downloadstartTime; // start of request

@end

@implementation MovieQueueItem

- (NSString *)description
{
    return [self URLString];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - YapImageManager
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static YapImageManager *_sharedInstance;

@implementation YapImageManager {
	YapImageSessionManager *_sessionManager;
	AFHTTPSessionManager *_gfycatSessionManager;
	YapImageSessionManager *_MP4SessionManager;
	
	// Database and Connections
	
	YapDatabase *_database;
	YapDatabaseConnection *_databaseConnection;
	YapDatabaseConnection *_backgroundDatabaseConnection;

	YapDatabase *_attributesDatabase;
	YapDatabaseConnection *_attributesDatabaseConnection;
	YapDatabaseConnection *_backgroundAttributesDatabaseConnection;

	NSMutableArray *_downloadQueue;
	NSMutableArray *_imageRequests;
	NSMutableDictionary *_pendingWritesDict;

	// queue of pending cancelled requests with GIF previews (first image of GIF)
	NSMutableDictionary *_cancelledRequestsWithGIFPreviewDict;

	// image async queue
	BOOL useQueue2;
	dispatch_queue_t imageDecodeQueue1;
	dispatch_queue_t imageDecodeQueue2;
	
	NSCache *_attributesCache;
	
	// GIF->MP4 queue
	NSMutableArray *_movieQueue;
	NSMutableArray *_movieRequests;
	dispatch_queue_t _movieEncodeQueue;
	

}

+ (YapImageManager *)sharedInstance
{
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [YapImageManager new];
    });
    
	return _sharedInstance;
}

- (id)init
{
	NSAssert(_sharedInstance == nil, @"You MUST use sharedInstance singleton.");
	
	if ((self = [super init]))
	{
		// used to download images
		NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
		config.HTTPMaximumConnectionsPerHost = MAX_SIMULTANEOUS_IMAGE_REQUESTS; // Note: this is not the same a max concurrent operations
		config.timeoutIntervalForRequest = 60.0; // 60 second timeout
		_sessionManager = [[YapImageSessionManager alloc] initWithSessionConfiguration:config];
		_sessionManager.delegate = self;
		_sessionManager.shouldPreloadImageAttributes = YES;
		_sessionManager.shouldPreloadGIFImageData = YES;
		_sessionManager.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer new];
		_sessionManager.responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"image/tiff", @"image/jpeg", @"image/jpg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];

		// used to download Gfycat MP4s
		NSURLSessionConfiguration *MP4Config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
		MP4Config.HTTPMaximumConnectionsPerHost = MAX_SIMULTANEOUS_IMAGE_REQUESTS; // Note: this is not the same a max concurrent operations
		MP4Config.timeoutIntervalForRequest = 60.0; // 60 second timeout
		_MP4SessionManager = [[YapImageSessionManager alloc] initWithSessionConfiguration:MP4Config];
		_MP4SessionManager.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _MP4SessionManager.responseSerializer = [AFHTTPResponseSerializer new];
		_MP4SessionManager.responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"video/mp4", nil];

		// used to check for Gfycat URLs (JSON)
		_gfycatSessionManager = [AFHTTPSessionManager manager];
		
		YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
		options.pragmaPageSize = 32768;
		options.aggressiveWALTruncationSize = 1024 * 1024 * 100;
		_database = [[YapDatabase alloc] initWithPath:[self databasePath]
									 objectSerializer:NULL
								   objectDeserializer:NULL
								   metadataSerializer:NULL
								 metadataDeserializer:NULL
								   objectPreSanitizer:NULL
								  objectPostSanitizer:NULL
								 metadataPreSanitizer:NULL
								metadataPostSanitizer:NULL
											  options:options];

		_attributesDatabase = [[YapDatabase alloc] initWithPath:[self attributesDatabasePath]];
		_downloadQueue = [NSMutableArray new];
		_imageRequests = [NSMutableArray new];
		_pendingWritesDict = [NSMutableDictionary new];
		_cancelledRequestsWithGIFPreviewDict = [NSMutableDictionary new];
				
		_attributesCache = [NSCache new];
		_attributesCache.countLimit = 1000.0;
		
		_movieQueue = [NSMutableArray array];    // in queue
		_movieRequests = [NSMutableArray array]; // rendering

		
		_movieEncodeQueue = dispatch_queue_create("YapImageManager.MovieEncode", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(_movieEncodeQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:AFNetworkingReachabilityDidChangeNotification
                                                   object:nil];

		[self removeExpiredMovies];
		[self removeExpiredImages];
        [self vacuumDatabaseIfNeeded];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Database
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)databasePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *databaseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *databaseName = @"YapImageManager20.sqlite";
	
	return [databaseDir stringByAppendingPathComponent:databaseName];
}

- (YapDatabaseConnection *)databaseConnection
{
	if (_databaseConnection == nil)
	{
		_databaseConnection = [_database newConnection];
		
		_backgroundDatabaseConnection.objectCacheEnabled = NO;
		_backgroundDatabaseConnection.metadataCacheEnabled = NO;
		_databaseConnection.objectPolicy = YapDatabasePolicyShare;
		_databaseConnection.metadataPolicy = YapDatabasePolicyShare;
	}
	
	return _databaseConnection;
}

- (YapDatabaseConnection *)backgroundDatabaseConnection
{
	if (_backgroundDatabaseConnection == nil)
	{
		_backgroundDatabaseConnection = [_database newConnection];
		
		_backgroundDatabaseConnection.objectCacheEnabled = NO;
		_backgroundDatabaseConnection.metadataCacheEnabled = NO;
		_backgroundDatabaseConnection.objectPolicy = YapDatabasePolicyShare;
		_backgroundDatabaseConnection.metadataPolicy = YapDatabasePolicyShare;
	}
	
	return _backgroundDatabaseConnection;
}

- (NSString *)attributesDatabasePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *databaseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *databaseName = @"YapURLImageAttributes20.sqlite";
	
	return [databaseDir stringByAppendingPathComponent:databaseName];
}


- (YapDatabaseConnection *)attrbutesDatabaseConnection
{
	if (_attributesDatabaseConnection == nil)
	{
		_attributesDatabaseConnection = [_attributesDatabase newConnection];
		
		_attributesDatabaseConnection.objectCacheLimit   = 4000;
		_attributesDatabaseConnection.metadataCacheLimit = 4000;
		_attributesDatabaseConnection.objectPolicy = YapDatabasePolicyShare;
		_attributesDatabaseConnection.metadataPolicy = YapDatabasePolicyShare;
	}
	
	return _attributesDatabaseConnection;
}

- (YapDatabaseConnection *)backgroundAttributesDatabaseConnection
{
	if (_backgroundAttributesDatabaseConnection == nil)
	{
		_backgroundAttributesDatabaseConnection = [_attributesDatabase newConnection];
		
		_backgroundAttributesDatabaseConnection.objectCacheEnabled = NO;
		_backgroundAttributesDatabaseConnection.metadataCacheEnabled = NO;
		_backgroundAttributesDatabaseConnection.objectPolicy = YapDatabasePolicyShare;
		_backgroundAttributesDatabaseConnection.metadataPolicy = YapDatabasePolicyShare;
	}
	
	return _backgroundAttributesDatabaseConnection;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image requests
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// is one or more queues available
- (BOOL)isReadyForImageProcessing
{
	//NSLog(@"QUEUE: %d ACTIVE: %d Reachable:%d\n%@", (int) _downloadQueue.count, (int) _imageRequests.count, YapApp.reachabilityManager.reachable, _imageRequests);

	BOOL isReachable = YES; // TODO: update to check reachability flag
	
	return (([_imageRequests count] < MAX_SIMULTANEOUS_IMAGE_REQUESTS) && isReachable);
}

- (ImageQueueItem *)imageRequestForURLString:(NSString *)URLString
{
	__block ImageQueueItem *imageRequest = nil;
	[_imageRequests enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ImageQueueItem *item = obj;
		if ([item.URLString isEqualToString:URLString]) {
			imageRequest = item;
			*stop = YES;
		}
	}];
	return imageRequest;
}

- (void)vacuumDatabaseIfNeeded
{
    __block BOOL needsVacuum = NO;
    
    YapDatabaseConnection *connection = [self backgroundDatabaseConnection];
    
    [connection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        NSString *auto_vacuum = [connection pragmaAutoVacuum];
        needsVacuum = [auto_vacuum isEqualToString:@"NONE"];
        
    } completionBlock:^{
        
        if (needsVacuum)
        {
            // We don't vacuum right away.
            // The app just launched, so it could be pulling down stuff from the server.
            // Instead, we queue up the vacuum operation to run after a slight delay.
            
            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
            dispatch_after(when, dispatch_get_main_queue(), ^{
                
                [connection asyncVacuumWithCompletionBlock:^{
                    
                    DDLogInfo(@"VACUUM complete (upgrading database auto_vacuum setting)");
                }];
            });
        }
    }];
}

- (void)saveImage:(NSData *)imageData forURLString:(NSString *)URLString
{
	// save to database
	NSDate *downloadTimestamp = [NSDate date];
	[_pendingWritesDict setObject:imageData forKey:[self imageKeyForURLString:URLString size:CGSizeZero]];

	// POST notification
	NSDictionary *userInfo = @{
							   YapImageManagerURLKey : URLString
							   };
	[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerUpdatedNotification object:self userInfo:userInfo];

	YapDatabaseConnection *connection = [self backgroundDatabaseConnection];
	[connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction){
		[transaction setObject:imageData forKey:[self imageKeyForURLString:URLString size:CGSizeZero] inCollection:kYapImageManagerImageCollection withMetadata:downloadTimestamp];
	}  completionBlock:^{
		[_pendingWritesDict removeObjectForKey:[self imageKeyForURLString:URLString size:CGSizeZero]];
	}];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Image request
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)downloadImageForRequest:(ImageQueueItem *)imageRequest
{
	
	NSDictionary *parameters = nil;
	
	void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {

		// remove queue item
		[self removeQueuedImageForURLString:imageRequest.URLString];
		imageRequest.progress = nil;
		[_imageRequests removeObject:imageRequest];

		// check to see if the request was cancelled
		NSData *cancelledGIFData = [_cancelledRequestsWithGIFPreviewDict objectForKey:imageRequest.URLString];
		if (error.code == NSURLErrorCancelled && cancelledGIFData) {
			//NSLog(@"Cancelled request due to fast download of GIF preview for %@; saving image", imageRequest.URLString);
			[self saveImage:cancelledGIFData forURLString:imageRequest.URLString];
			[_cancelledRequestsWithGIFPreviewDict removeObjectForKey:imageRequest.URLString];
		} else {
		
			// POST failed notification
			NSDictionary *userInfo = @{
									   YapImageManagerURLKey : imageRequest.URLString
									   };
			[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerFailedNotification object:self userInfo:userInfo];
			
			DDLogInfo(@"Error: %@", error);

		}
		
		[self processImageQueue];
	};
	
	void (^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
		
		__block NSData *imageData = responseObject;
		if (imageData) {
			dispatch_async([self imageAsyncQueue], ^{ @autoreleasepool {
				
				// update the image attributes, if necessary
				NSDictionary *imageAttributes = [self imageAttributesForURLString:imageRequest.URLString];
				CGSize imageSize = CGSizeZero;
				BOOL shouldUpdateImageAttributes = NO; // only if dirty
				if (!imageAttributes) {
					UIImage *image = [UIImage imageWithData:imageData];
					CGFloat scale = [[UIScreen mainScreen] scale];
					imageSize = (CGSize) {
						.width = image.size.width * scale,
						.height = image.size.height * scale
					};
					//NSLog(@"** UPDATING MISSING IMAGE ATTRIBUTES FOR URL %@", URLString);
					shouldUpdateImageAttributes = YES; // update image size attribute with actual image size; this should only be required if we were unable to pick up the image dimensions from the headers during download
				} else {
					imageSize = [self imageSizeForImageWithAttributes:imageAttributes];
				}
				
				// Resize image to max size, if necessary
				CGSize maxSize = [self maxSizeForImageWithSize:imageSize maxWidthHeight:4096.0];
				//NSLog(@"SAVE IMAGE WITH DIMENSIONS %f %f %@", imageSize.width, imageSize.height, URLString);
				
				if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
					imageSize = [self maxSizeForImageWithSize:imageSize maxWidthHeight:1024.0];
					shouldUpdateImageAttributes = YES;
					
					//NSLog(@"** RESIZE LARGE IMAGE TO %@", NSStringFromCGSize(imageSize));
					UIImage *image = [UIImage imageWithData:imageData];
					UIImage *resizedImage = [self imageWithAspectFillCPU:image size:imageSize]; // Image is too large for GPU, use CPU
					imageData = UIImageJPEGRepresentation(resizedImage, 0.8);
				}
				
				if (shouldUpdateImageAttributes) {
					[self updateImageAttributesWithSize:imageSize forURLString:imageRequest.URLString];
				}
				
				// dispatch next request on main thread
				dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
					
					// remove queue item
					[self removeQueuedImageForURLString:imageRequest.URLString];
					imageRequest.progress = nil;
					[_imageRequests removeObject:imageRequest];
					[self saveImage:imageData forURLString:imageRequest.URLString];
					
					//NSLog(@"DOWNLOADED IMAGE (%0.1f sec, %d queued): %@", -[imageRequest.downloadstartTime timeIntervalSinceNow], (int) _downloadQueue.count, imageRequest.URLString);
					
					[self processImageQueue];
				}});
			}});
		} else {
			// TODO: write NULL to database
		}
	};
	
    NSURLSessionDataTask *task = [_sessionManager GET:imageRequest.URLString parameters:parameters progress:NULL success:successBlock failure:failureBlock];
	
	// save pointer to download progress
	imageRequest.progress = [_sessionManager downloadProgressForTask:task];
	imageRequest.downloadstartTime = [NSDate date];
	
	// POST notification
	NSDictionary *userInfo = @{
							   YapImageManagerURLKey : imageRequest.URLString
							   };
	[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerImageWillBeginDownloadingNotification object:self userInfo:userInfo];

}

- (NSProgress *)downloadProgressForURLString:(NSString *)URLString
{

	ImageQueueItem *imageRequest = [self imageRequestForURLString:URLString];

	if (imageRequest) {
		return imageRequest.progress;
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image APIs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)imageForURLString:(NSString *)URLString completion:(void(^)(UIImage *image, NSString *URLString))completion;
{
	[self imageForURLString:URLString size:CGSizeZero completion:completion];
}

- (void)queueImageForURLString:(NSString *)URLString
{
	[self queueImageForURLString:URLString size:CGSizeZero];
}

- (void)backgroundQueueImageForURLString:(NSString *)URLString
{
	[self backgroundQueueImageForURLString:URLString size:CGSizeZero];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Download APIs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)imageKeyForURLString:(NSString *)URLString size:(CGSize)size
{
	// size is currently ignored since full sized image is always stored in database
	return URLString;
}

- (void)imageForURLString:(NSString *)URLString size:(CGSize)size completion:(void(^)(UIImage *image, NSString *URLString))completion;
{
	__block NSData *imageData = [_pendingWritesDict objectForKey:[self imageKeyForURLString:URLString size:CGSizeZero]];
	
	// check database
	dispatch_async([self imageAsyncQueue], ^{ @autoreleasepool {
		
		if (!imageData) {
			[[self databaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
				imageData = [transaction objectForKey:[self imageKeyForURLString:URLString size:CGSizeZero] inCollection:kYapImageManagerImageCollection];
			}];
		}
		
		// TODO: check to see if image is old and redownload on background queue
		
		UIImage *image = nil;
		if (imageData) {
			image = [[UIImage alloc] initWithData:imageData scale:[[UIScreen mainScreen] scale]];
		}
		
		// if the full sized image was found, save resized thumbnail size to disk and return
		if (image) {
			UIImage *decodedImage = nil;
			// does image requires a resize?
			if (CGSizeEqualToSize(size, CGSizeZero)) {
				// no, just decode, up to a max size
				
				CGSize maxSize = [self maxSizeForImageWithSize:image.size maxWidthHeight:1024.0];
				if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
					//NSLog(@"RESIZE IMAGE WITH DIMENSIONS %f %f %@", image.size.width, image.size.height, URLString);
					decodedImage = [self imageWithAspectFillCPU:image size:maxSize];
				} else {
					//NSLog(@"DECODE IMAGE WITH DIMENSIONS %f %f %@", image.size.width, image.size.height, URLString);
					decodedImage = [self imageWithAspectFillCPU:image size:image.size];
				}
			} else {
				// else resize
				decodedImage = [self imageWithAspectFillCPU:image size:size];
			}
						
			dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
				if (!decodedImage) {
					DDLogError(@"Failed to resize image with URL %@", URLString);
				}
				completion(decodedImage, URLString);
			}});
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
				if (image) {
					completion(image, URLString);
				} else {
					// add to queue to download
					[self queueImageForURLString:URLString size:size];
					completion(nil, URLString);
				}
			}});
		}
	}});
}

- (UIImage *)cachedImageForURLString:(NSString *)URLString
{
	return [self cachedImageForURLString:URLString size:CGSizeZero];
}

- (UIImage *)cachedImageForURLString:(NSString *)URLString size:(CGSize)size
{
	// check the database
	__block NSData *imageData = nil;
	
	[[self databaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		imageData = [transaction objectForKey:[self imageKeyForURLString:URLString size:CGSizeZero] inCollection:kYapImageManagerImageCollection];
	}];
	
	if (imageData) {
		return [[UIImage alloc] initWithData:imageData scale:[[UIScreen mainScreen] scale]];
	}
	
	return nil;
}

- (NSData *)gifFromMovieURL:(NSString *)url
{
// TODO: This is slow. Is there a faster way?
	__block NSData *data = nil;

	[self movieForURLString:url completion:^(NSString *movieURL, NSString *URLString) {
		NSURL *fileURL = [NSURL fileURLWithPath:movieURL];
		if (fileURL == nil) {
			return;
		}
		AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
		AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
		generator.appliesPreferredTrackTransform = YES;
		generator.requestedTimeToleranceBefore = kCMTimeZero;
		generator.requestedTimeToleranceAfter = kCMTimeZero;

		NSMutableArray *images = [NSMutableArray array];
		NSMutableArray *times = [NSMutableArray array];
		float fps = 12;
		float length = CMTimeGetSeconds(asset.duration);
		for (float i = 0; i < length; i += 1/fps) {
			[times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(i, asset.duration.timescale)]];
			CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(i, asset.duration.timescale) actualTime:NULL error:NULL];
			UIImage *image = [UIImage imageWithCGImage:cgImage];
			[images addObject:image];
			
			CFRelease(cgImage);
		}

		NSUInteger const kFrameCount = times.count;
		NSDictionary *fileProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: @{
												 (__bridge id)kCGImagePropertyGIFLoopCount: @0
												 }
										 };
		float frameDur = roundf(1 / fps * 100) / 100.0;
		NSDictionary *frameProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: @{
												  (__bridge id)kCGImagePropertyGIFDelayTime: @(frameDur)
												  }
										  };
		CFMutableDataRef gifDataRef = CFDataCreateMutable(kCFAllocatorDefault, 0);
		CGImageDestinationRef destination = CGImageDestinationCreateWithData(gifDataRef, kUTTypeGIF, kFrameCount, NULL);
		CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);

		for (NSUInteger i = 0; i < kFrameCount; i++) {
			@autoreleasepool {
				UIImage * image = [images objectAtIndex:i];
				CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
			}
		}

		if (CGImageDestinationFinalize(destination)) {
			data = [NSData dataWithData:(__bridge NSData *)(gifDataRef)];
		} else {
			DDLogVerbose(@"failed to finalize image destination");
		}

		CFRelease(destination);
		CFRelease(gifDataRef);
	}];

	return data;
}

- (NSData *)imageDataForURLString:(NSString *)URLString
{
	// check the database
	__block NSData *imageData = nil;
	
	[[self databaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		imageData = [transaction objectForKey:[self imageKeyForURLString:URLString size:CGSizeZero] inCollection:kYapImageManagerImageCollection];
	}];
	
	return imageData;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image queue
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (ImageQueueItem *)imageQueueItemForURLString:(NSString *)URLString
{
	__block ImageQueueItem *foundItem = nil;
	
	if (URLString) {
		[_downloadQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			ImageQueueItem *item = obj;
			if ([item.URLString isEqualToString:URLString]) {
				foundItem = item;
				*stop = YES;
			}
		}];
	}
	
	return foundItem;
}

- (BOOL)isImageQueuedForURLString:(NSString *)URLString
{
	// NOTE: Active imageRequests remain on downloadQueue, so it's only necessary to check downloadQueue
	ImageQueueItem *foundItem = [self imageQueueItemForURLString:URLString];
	return (foundItem != nil);
}

- (void)prioritizeImageForURLString:(NSString *)URLString
{
	ImageQueueItem *foundItem = [self imageQueueItemForURLString:URLString];
	
	if (foundItem) {
		// move to end of list to bump priority
		if (![self imageRequestForURLString:URLString]) {
			[_downloadQueue removeObject:foundItem];
			[_downloadQueue addObject:foundItem];
			//NSLog(@"PRIORITIZE IMAGE FOR URL %@", URLString);
		}
		
	}
}

- (void)backgroundQueueImageForURLString:(NSString *)URLString size:(CGSize)size
{
	ImageQueueItem *foundItem = [self imageQueueItemForURLString:URLString];
	
	if (!foundItem) {
		ImageQueueItem *item = [ImageQueueItem new];
		item.URLString = [URLString copy];
		item.size = size;
		if (_downloadQueue.count) {
			[_downloadQueue insertObject:item atIndex:0]; // add to "back" of list
		} else {
			[_downloadQueue addObject:item];
		}
	}
	[self processImageQueue];
}

- (void)queueImageForURLString:(NSString *)URLString size:(CGSize)size
{
	ImageQueueItem *foundItem = [self imageQueueItemForURLString:URLString];
	
	if (!foundItem) {
		ImageQueueItem *item = [ImageQueueItem new];
		item.URLString = [URLString copy];
		item.size = size;
		[_downloadQueue addObject:item];
	} else {
		// move to end of list to bump priority, if not already downloading
		if (![self imageRequestForURLString:URLString]) {
			[_downloadQueue removeObject:foundItem];
			[_downloadQueue addObject:foundItem];
			//NSLog(@"SET TOP PRIORITY FOR URL %@", URLString);
		}
		
	}
	[self processImageQueue];
}

- (void)removeQueuedImageForURLString:(NSString *)URLString
{
	ImageQueueItem *foundItem = [self imageQueueItemForURLString:URLString];
	if (foundItem) {
		[_downloadQueue removeObject:foundItem];
	}
}

- (ImageQueueItem *)nextImageQueueItem
{
	__block ImageQueueItem *foundItem = nil;
	
	// reverse enumerate, so most recent items are downloaded first
	[_downloadQueue enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		// is not isDownloading (in queue)
		ImageQueueItem *item = obj;
		if (![self imageRequestForURLString:item.URLString]) {
			foundItem = item;
			*stop = YES;
		}
	}];
	return  foundItem;
}

- (void)processImageQueue
{
	if (![self isReadyForImageProcessing]) return;
	
	// process image
	if ([_downloadQueue count]) {
		
		ImageQueueItem *item = [self nextImageQueueItem];
		if (item) {
			ImageQueueItem *imageRequest = [ImageQueueItem new];
			imageRequest.URLString = item.URLString;
			imageRequest.size = item.size;
			[_imageRequests addObject:imageRequest];

			// start image download
			[self downloadImageForRequest:imageRequest];
			
			
			//NSLog(@"DOWNLOAD IMAGE FOR URL %@", imageRequest.URLString);
			
		}
	}
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image processing queue
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (dispatch_queue_t)imageAsyncQueue
{
	dispatch_queue_t queue = NULL;
	if (!useQueue2) {
		if (!imageDecodeQueue1) {
			imageDecodeQueue1 = dispatch_queue_create("YapImageManager.imageDecode.1", DISPATCH_QUEUE_SERIAL);
			dispatch_set_target_queue(imageDecodeQueue1, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
		}
		queue = imageDecodeQueue1;
	} else {
		if (!imageDecodeQueue2) {
			imageDecodeQueue2 = dispatch_queue_create("YapImageManager.imageDecode.2", DISPATCH_QUEUE_SERIAL);
			dispatch_set_target_queue(imageDecodeQueue2, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
		}
		queue = imageDecodeQueue2;
	}
	useQueue2 = !useQueue2;

	return queue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image resizing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIImage *)imageWithAspectFillCPU:(UIImage *)image size:(CGSize)size
{
	UIImage *aspectFillImage = nil;
	
	UIGraphicsBeginImageContextWithOptions(size, YES, [[UIScreen mainScreen] scale]);
	
	// draw the image, aspect fill
	CGRect imageRect = (CGRect) { .size = size };
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// draw the image aspect fill
	CGContextAddRect(context, imageRect);
	CGContextClip(context);
	CGRect aspectFillRect = [image aspectFillRectForRect:imageRect withFaceCentroid:nil];
	
	// Flip the context because UIKit coordinate system is upside down to Quartz coordinate system
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
	
    // Draw the original image to the context
    CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	// set interpolation quality
    CGContextSetInterpolationQuality(context, kCGInterpolationDefault);
	
	// Draw the image
	CGContextDrawImage(context, aspectFillRect, image.CGImage);
	
	// capture the image
	aspectFillImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();

	return aspectFillImage;
}

// Resizes on GPU using Core Image
- (UIImage *)imageWithAspectFillGPU:(UIImage *)image size:(CGSize)size
{
	CGFloat scale = [[UIScreen mainScreen] scale];
	CGRect imageRect = (CGRect) { .size.width = size.width * scale, .size.height = size.height * scale };
	CGRect aspectFillRect = [image aspectFillRectForRect:imageRect withFaceCentroid:nil];
	
	CGSize newSize = aspectFillRect.size;
	CGRect cropRect = (CGRect) { .size = newSize };
	
	// calculate the new size and crop rect for aspect fill
	if (aspectFillRect.origin.x < 0.0) {
		// crop left/right edge
		newSize = (CGSize) {
			.width = 2.0 * -aspectFillRect.origin.x + aspectFillRect.size.width,
			.height = aspectFillRect.size.height
		};
		cropRect = CGRectOffset(aspectFillRect, -aspectFillRect.origin.x, 0.0); // move over rect to 0, 0
	} else if (aspectFillRect.origin.y < 0.0) {
		// crop top/bottom edge
		newSize = (CGSize) {
			.width = aspectFillRect.size.width,
			.height = 2.0 * -aspectFillRect.origin.y + aspectFillRect.size.height
		};
		cropRect = CGRectOffset(aspectFillRect, 0.0, -aspectFillRect.origin.y);
	}
	
	CIImage *beginImage = [CIImage imageWithCGImage:image.CGImage];

	// open GPU context
	EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null] };
	CIContext *context = [CIContext contextWithEAGLContext:myEAGLContext options:options];
	
	// scale image
	CGAffineTransform transform = CGAffineTransformMakeScale(newSize.width / (image.size.width * scale), newSize.height / (image.size.height * scale));
	CIImage *outputImage = [beginImage imageByApplyingTransform:transform];

	// crop image, if necessary
	if (!CGSizeEqualToSize(newSize, cropRect.size))
		outputImage = [outputImage imageByCroppingToRect:cropRect];

	CGRect rect = CGRectIntegral([outputImage extent]);
	CGImageRef CGImage = [context createCGImage:outputImage fromRect:rect];
	UIImage *result = [UIImage imageWithCGImage:CGImage scale:scale orientation:UIImageOrientationUp];
	CGImageRelease(CGImage);
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image attributes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Handles posting notification to the main thread.
 **/
- (void)postImageAttributesNotification:(NSDictionary *)imageAttributes forURLString:(NSString *)URLString
{
	dispatch_block_t block = ^{
		
		NSDictionary *attributes = @{YapImageManagerURLKey: URLString ?: @"",
									 YapImageManagerImageAttributesKey: imageAttributes ?: @""
									 };

		[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerImageAttributesUpdatedNotification
		                                                    object:self
		                                                  userInfo:attributes];
	};
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

- (void)setImageAttributes:(NSDictionary *)imageAttributes forURLString:(NSString *)URLString
{
	//NSLog(@"Save attributes for URL %@", URLString);
	
	[_attributesCache setObject:imageAttributes forKey:URLString];
	[self postImageAttributesNotification:imageAttributes forURLString:URLString];
	
	// save to database
	NSDate *downloadTimestamp = [NSDate date];
	YapDatabaseConnection *connection = [self backgroundAttributesDatabaseConnection];
	//NSLog(@"WRITE ATTRIBUTES TO DATABASE FOR %@", URLString);
	[connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction){
		[transaction setObject:imageAttributes forKey:URLString inCollection:kYapImageManagerImageAttributesCollection withMetadata:downloadTimestamp];
	}  completionBlock:^{
		//NSLog(@"**WRITE ATTRIBUTES COMPLETE FOR %@", URLString);
	}];
}

- (void)updateImageAttributesWithSize:(CGSize)size forURLString:(NSString *)URLString
{
	NSDictionary *imageAttributes = [self imageAttributesForURLString:URLString];
	if (imageAttributes) {
		NSMutableDictionary *updatedAttributes = [imageAttributes mutableCopy];
		NSNumber *width = [updatedAttributes objectForKey:@"image_width"];
		NSNumber *height = [updatedAttributes objectForKey:@"image_height"];
		
		// update only if dimensions have changed
		if (width && [width floatValue] != size.width && height && [height floatValue] != size.height) {
			[updatedAttributes setObject:[NSNumber numberWithFloat:size.width] forKey:@"image_width"];
			[updatedAttributes setObject:[NSNumber numberWithFloat:size.height] forKey:@"image_height"];
			[self setImageAttributes:[updatedAttributes copy] forURLString:URLString];
		}
	} else {
		// no image attribute data exists, so set size and width and save to database
		imageAttributes = @{@"image_width": [NSNumber numberWithFloat:size.width],
							@"image_height": [NSNumber numberWithFloat:size.height]
							};
		[self setImageAttributes:imageAttributes forURLString:URLString];
	}
}

- (NSDictionary *)imageAttributesForURLString:(NSString *)URLString;
{
	// check the database
	__block NSDictionary *imageAttributes = nil;
	
	imageAttributes = [_attributesCache objectForKey:URLString];
	
	if (!imageAttributes) {
		// check database
		if (![self isImageQueuedForURLString:URLString]) {
			//NSLog(@"READ ATTRIBUTES FROM DATABASE FOR %@", URLString);
			[[self attrbutesDatabaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
				imageAttributes = [transaction objectForKey:URLString inCollection:kYapImageManagerImageAttributesCollection];
			}];
			if (imageAttributes) {
				// save in cache
				[_attributesCache setObject:imageAttributes forKey:URLString];
			}
		} else {
			//NSLog(@"**SKIP READ ATTRIBUTES; QUEUED %@", URLString);
		}
	} else {
		//NSLog(@"CACHED ATTRIBUTES FOR URL %@", URLString);
	}
	
	return imageAttributes;
}

- (CGSize)imageSizeForImageWithAttributes:(NSDictionary *)imageAttributes
{
	CGSize imageSize = CGSizeZero;
	
	NSNumber *width = [imageAttributes objectForKey:@"image_width"];
	NSNumber *height = [imageAttributes objectForKey:@"image_height"];
	
	if (width && height) {
		imageSize = (CGSize) {
			.width = [width floatValue],
			.height = [height floatValue]
		};
	}
	return imageSize;
}

// return CGRectZero if image does not need resizing, otherwise a new size with same aspect
- (CGSize)maxSizeForImageWithSize:(CGSize)imageSize maxWidthHeight:(CGFloat)maxWidthHeight
{
	CGSize maxSize = CGSizeZero;
	if (imageSize.width > maxWidthHeight || imageSize.height > maxWidthHeight) {
		if (imageSize.width > imageSize.height) {
			maxSize = (CGSize) {
				.width = maxWidthHeight,
				.height = roundf(maxWidthHeight * imageSize.height / imageSize.width)
			};
		} else {
			maxSize = (CGSize) {
				.width = roundf(maxWidthHeight * imageSize.width / imageSize.height),
				.height = maxWidthHeight,
			};
		}
	}
	return maxSize;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image Session Manager
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)imageSessionManager:(YapImageSessionManager *)sessionManager imageAttributesFound:(NSDictionary *)imageAttributes forURLString:(NSString *)URLString;
{
	// save to database
	[self setImageAttributes:imageAttributes forURLString:URLString];
	
}

- (void)imageSessionManager:(YapImageSessionManager *)sessionManager GIFImageDataFound:(NSData *)imageData forURLString:(NSString *)URLString shouldCancelRequest:(BOOL *)shouldCancelRequest;
{
	
	BOOL isMovieDownload = [self isMovieQueuedForURLString:URLString];
	if (!isMovieDownload) {
		// save the image and stop the download since we only need the first image of a GIF to show a preview
		// do not stop movie download requests, since the full GIF is required to generate a movie file
		[_cancelledRequestsWithGIFPreviewDict setObject:imageData forKey:URLString];
		*shouldCancelRequest = YES;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Animated GIFs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// borrowed from OLImageView by by Diego Torres
inline static NSTimeInterval CGImageSourceGetGifFrameDelay(CGImageSourceRef imageSource, NSUInteger index)
{
    NSTimeInterval frameDuration = 0;
    CFDictionaryRef theImageProperties;
    if ((theImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL))) {
        CFDictionaryRef gifProperties;
        if (CFDictionaryGetValueIfPresent(theImageProperties, kCGImagePropertyGIFDictionary, (const void **)&gifProperties)) {
            const void *frameDurationValue;
            if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFUnclampedDelayTime, &frameDurationValue)) {
                frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                if (frameDuration <= 0) {
                    if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFDelayTime, &frameDurationValue)) {
                        frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                    }
                }
            }
        }
        CFRelease(theImageProperties);
    }
    
    //Implement as Browsers do.
    //See:  http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility
    //Also: http://blogs.msdn.com/b/ieinternals/archive/2010/06/08/animated-gifs-slow-down-to-under-20-frames-per-second.aspx
    
    if (frameDuration < 0.02 - FLT_EPSILON) {
        frameDuration = 0.1;
    }
    return frameDuration;
}
- (NSString *)movieFilenameForURLString:(NSString *)URLString
{
	static NSString *_documentsDirectoryPath = nil;
	
	if (!_documentsDirectoryPath) {
		_documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	}
	
	NSString *hash = [URLString md5Hash];

	NSString *fullPath = [NSString stringWithFormat:@"%@/%@.mp4", _documentsDirectoryPath, hash];
	return fullPath;

}

- (void)decodeGIFInfoFromCGImageSource:(CGImageSourceRef)imageSource imageCount:(NSUInteger *)imagesCountPtr durationPtr:(CGFloat *)durationPtr
{
	CGFloat totalDuration = 0.0;
	
	if (imageSource) {
		*imagesCountPtr = (int)CGImageSourceGetCount(imageSource);
		
		
		for (int idx = 0; idx < *imagesCountPtr; idx ++) {
			// get duration
			NSTimeInterval frameDuration = CGImageSourceGetGifFrameDelay(imageSource, idx);
			totalDuration += frameDuration;
			
			if (idx >= 400) {
				// this is never hit, but a failsafe in case someone uploads an extremely large GIF that could crash the feed
				break; // max frames
			}
		}
	}
	// return the images
	*durationPtr = totalDuration;
}

- (CGImageRef)CGImageFromCGImageSource:(CGImageSourceRef)imageSource atIndex:(NSUInteger)index
{
	CGImageRef cgImage = NULL;
	
	if (imageSource) {
		cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, NULL);
	}
	return cgImage;
}

-(void)createMovieFromImageData:(NSData *)imageData forURLString:(NSString *)URLString progress:(NSProgress *)progress completion:(void(^)(BOOL success))completion;
{
	CFDataRef CFData = CFDataCreate(NULL, [imageData bytes], [imageData length]);
	CGImageSourceRef imageSource =  CGImageSourceCreateWithData(CFData, NULL);
	
	@try {
		// add a try/catch, to catch potential assertions in appendPixelBuffer and newPixelBufferFromCGImage
		
		NSUInteger imagesCount;
		CGFloat duration;
		[self decodeGIFInfoFromCGImageSource:imageSource imageCount:&imagesCount durationPtr:&duration];
		
		// at least 2 frames required for a movie
		if (imagesCount < 2) {
			completion(NO);
			CFRelease(imageSource);
			CFRelease(CFData);
			return;
		}
		
		NSString *movieFilename = [self movieFilenameForURLString:URLString];
		
		CGImageRef CGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		CGSize imageSize = (CGSize) { .width = CGImageGetWidth(CGImage), .height = CGImageGetHeight(CGImage) };
		
		// adjust width & height to even multiple to avoid border artifacts
		NSInteger width = imageSize.width;
		if (width % 2) {
			width--;
		}
		NSInteger height = imageSize.height;
		if (height % 2) {
			height--;
		}
		
		CGSize size = (CGSize)  { .width = width, .height = height };
		
		//NSLog(@"%@: load frame %d (%zu %zu)", URLString, 0, CGImageGetWidth(CGImage), CGImageGetHeight(CGImage));
		
		NSError *error = nil;
		
		AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
									  [NSURL fileURLWithPath:movieFilename] fileType:AVFileTypeMPEG4
																  error:&error];
		NSParameterAssert(videoWriter);
		
		NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									   AVVideoCodecH264, AVVideoCodecKey,
									   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
									   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
									   AVVideoScalingModeResize, AVVideoScalingModeKey,
									   
									   [NSDictionary dictionaryWithObjectsAndKeys:
#ifdef USE_HIGH_BITRATE
										[NSNumber numberWithInteger:1960000], AVVideoAverageBitRateKey,
#endif
										[NSNumber numberWithInteger:1], AVVideoMaxKeyFrameIntervalKey,
										nil], AVVideoCompressionPropertiesKey,
									   
									   
									   nil];
		
		
		AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
												assetWriterInputWithMediaType:AVMediaTypeVideo
												outputSettings:videoSettings];
		
		
		
		NSDictionary* sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
													 [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
													 [NSNumber numberWithInt: size.width], kCVPixelBufferWidthKey,
													 [NSNumber numberWithInt: size.height], kCVPixelBufferHeightKey,
													 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
													 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
													 nil];
		
		AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
														 assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
														 sourcePixelBufferAttributes:sourcePixelBufferAttributes];
		
		NSParameterAssert(videoWriterInput);
		
		NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
		videoWriterInput.expectsMediaDataInRealTime = YES;
		videoWriterInput.mediaTimeScale = TARGET_MEDIA_TIMESCALE;
		[videoWriter addInput:videoWriterInput];
		
		//Start a session:
		[videoWriter startWriting];
		[videoWriter startSessionAtSourceTime:kCMTimeZero];
		
		
		//Video encoding
		
		CVPixelBufferRef buffer = NULL;
		
		int frameCount = 0;
		CGFloat FPS = imagesCount / duration;
		
		while (frameCount < imagesCount)
		{
			CGFloat unitCount = (CGFloat) frameCount / (CGFloat) imagesCount;
			CGFloat unitCountRounded = roundf(unitCount * 10.0); // round to 1/10
			progress.totalUnitCount = (int64_t) 10;
			progress.completedUnitCount = (int64_t) unitCountRounded;
			
			CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;

			// create the pixel buffer
			buffer = [self newPixelBufferFromCGImage:(CGImageRef)CGImage imageSize:imageSize size:size bufferPool:bufferPool];
			CGImageRelease(CGImage);
			
			BOOL append_ok = NO;
			int retries = 0;
			
			if (buffer) {
				while (!append_ok && retries < 30)
				{
					if (adaptor.assetWriterInput.readyForMoreMediaData)
					{
						//NSLog(@"appending %d attemp %d\n", frameCount, j);
						
						CMTime frameTime = CMTimeMakeWithSeconds(frameCount * 1.0/((CGFloat)FPS), TARGET_MEDIA_TIMESCALE);
						
						append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
						
						//[NSThread sleepForTimeInterval:1.0/((CGFloat)FPS)];
					}
					else
					{
						//NSLog(@"adaptor not ready %d, %d\n", frameCount, j);
						[NSThread sleepForTimeInterval:0.1];
					}
					retries++;
				}
				CVBufferRelease(buffer);
			}
			
			if (!append_ok)
			{
				DDLogWarn(@"**ERROR CREATING MP4 FILE FOR %@ (FRAME %d, %d attempts)", URLString, frameCount, retries);
				[videoWriter cancelWriting];
				completion(NO);
				CFRelease(imageSource);
				CFRelease(CFData);
				return;
			}
			frameCount++;
			if (frameCount < imagesCount) {
				// load next frame
				CGImage = CGImageSourceCreateImageAtIndex(imageSource, frameCount, NULL);
				//NSLog(@"%@: load frame %d (%zu %zu)", URLString, frameCount, CGImageGetWidth(CGImage), CGImageGetHeight(CGImage));
			}
		}
		
		[videoWriterInput markAsFinished];
		[videoWriter finishWritingWithCompletionHandler:^{
			DDLogVerbose(@"CONVERT GIF->MP4 (%lu FRAMES, %f seconds) FOR %@", (unsigned long)imagesCount, duration, URLString);
			completion(videoWriter.status == AVAssetWriterStatusCompleted);
		}];
		
		CFRelease(imageSource);
		CFRelease(CFData);
		
	}
	@catch (NSException *exception) {
		// failed to generate MP4 due to exception
		NSLog(@"WARNING: Failed to generate MP4 for %@; an exception was caught in createMovieFromImageData.", URLString);
		completion(NO);
		CFRelease(imageSource);
		CFRelease(CFData);
	}

}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image imageSize:(CGSize)imageSize size:(CGSize)size bufferPool:(CVPixelBufferPoolRef)bufferPool
{
    CVPixelBufferRef pxbuffer = NULL;

#ifdef DEBUG
	CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, bufferPool, &pxbuffer);
#endif

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
	
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
	
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pxbuffer);
	
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
												 size.height,
												 8,
												 bytesPerRow,
												 rgbColorSpace,
												 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);

    CGContextSetBlendMode(context, kCGBlendModeCopy);

	// don't scale the image if dimensions are not the same, just crop; using imageSize rather than size
	CGContextDrawImage(context, (CGRect) { .size = imageSize }, image);

	CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
	
    return pxbuffer;
}

- (void)movieForURLString:(NSString *)URLString completion:(void(^)(NSString *movieFilename, NSString *URLString))completion;
{
	[self movieForURLString:URLString gfycatId:nil isImgurGifv:NO completion:completion];
}

- (NSData *)movieDataForURLString:(NSString *)URLString movieFileName:(NSString **)movieFilename
{
	NSData *movieData = nil;
	
	// check to make sure movie is not currently
	if ([self isMovieQueuedForURLString:URLString]) {
		
		// bump the priority the movie is in the queue
		NSInteger foundIndex = [_movieQueue indexOfObject:URLString];
		
		if (foundIndex != NSNotFound) {
			// move to end of the list to bump priority
			NSString *foundItem = [_movieQueue objectAtIndex:foundIndex];
			[_movieQueue removeObjectAtIndex:foundIndex];
			[_movieQueue addObject:foundItem];
		}
		
	} else {
		
		// check to see if the file exists
		*movieFilename = [self movieFilenameForURLString:URLString];
		if ([[NSFileManager defaultManager] fileExistsAtPath:*movieFilename]) {
			movieData = [NSData dataWithContentsOfFile:*movieFilename];
		} else {
			[self queueMovieForURLString:URLString gfycatId:nil isImgurGifv:NO];
		}
	}
	
	return movieData;
}

- (void)movieForURLString:(NSString *)URLString gfycatId:(NSString *)gfycatId isImgurGifv:(BOOL)isImgurGifv completion:(void(^)(NSString *movieFilename, NSString *URLString))completion;
{
	// check to make sure movie is not currently
	if ([self isMovieQueuedForURLString:URLString]) {

		// bump the priority the movie is in the queue
		NSInteger foundIndex = [_movieQueue indexOfObject:URLString];
		
		if (foundIndex != NSNotFound) {
			// move to end of the list to bump priority
			NSString *foundItem = [_movieQueue objectAtIndex:foundIndex];
			[_movieQueue removeObjectAtIndex:foundIndex];
			[_movieQueue addObject:foundItem];
		}

	} else {
	
		// check to see if the file exists
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ @autoreleasepool {
			
			NSString *filename = [self movieFilenameForURLString:URLString];
			
			BOOL movieExists = NO;
			if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
				movieExists = YES;
			}
			dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
				if (movieExists) {
					completion(filename, URLString);
				} else {
					[self queueMovieForURLString:URLString gfycatId:gfycatId isImgurGifv:isImgurGifv];
				}
			}});
		}});
	}
}

// is one or more queues available
- (BOOL)isReadyForMovieProcessing
{
	BOOL isReachable = YES; // TODO: update to check reachability flag
	
	//NSLog(@"MOVIE QUEUE: %d ACTIVE: %d Reachable:%d", (int) _movieQueue.count, (int) _movieRequests.count, YapApp.reachabilityManager.reachable);
	return (([_movieRequests count] < MAX_SIMULTANEOUS_MOVIE_REQUESTS) && isReachable);
}


- (MovieQueueItem *)movieQueueItemForURLString:(NSString *)URLString
{
	__block MovieQueueItem *foundItem = nil;
	
	[_movieQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		MovieQueueItem *item = obj;
		if ([item.URLString isEqualToString:URLString]) {
			foundItem = item;
			*stop = YES;
		}
	}];
	
	return foundItem;
}

- (MovieQueueItem *)movieRequestForURLString:(NSString *)URLString
{
	__block MovieQueueItem *foundItem = nil;
	
	[_movieRequests enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		MovieQueueItem *item = obj;
		if ([item.URLString isEqualToString:URLString]) {
			foundItem = item;
			*stop = YES;
		}
	}];
	
	return foundItem;
}

- (BOOL)isMovieQueuedForURLString:(NSString *)URLString
{
	// NOTE: Active movieRequests remain on downloadQueue, so it's only necessary to check movieQueue
	MovieQueueItem *foundItem = [self movieQueueItemForURLString:URLString];
	return (foundItem != nil);
}

- (void)queueMovieForURLString:(NSString *)URLString gfycatId:(NSString *)gfycatId isImgurGifv:(BOOL)isImgurGifv
{
	MovieQueueItem *foundItem = [self movieQueueItemForURLString:URLString];
	
	if (!foundItem) {
		MovieQueueItem *item = [MovieQueueItem new];
		item.URLString = [URLString copy];
		item.gfycatId = [gfycatId copy];
		item.isImgurGifv = isImgurGifv;
		[_movieQueue addObject:item];
	} else {
		// move to end of list to bump priority, if not already downloading
		if (![self movieRequestForURLString:URLString]) {
			[_movieQueue removeObject:foundItem];
			[_movieQueue addObject:foundItem];
		}
		
	}
	[self processMovieQueue];
}

- (void)removeQueuedMovieForURLString:(NSString *)URLString
{
	MovieQueueItem *foundItem = [self movieQueueItemForURLString:URLString];
	if (foundItem) {
		[_movieQueue removeObject:foundItem];
	}
}

- (MovieQueueItem *)nextMovieQueueItem
{
	__block MovieQueueItem *foundItem = nil;
	
	// reverse enumerate, so most recent items are downloaded first
	[_movieQueue enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		// is not isDownloading (in queue)
		MovieQueueItem *item = obj;
		if (![self movieRequestForURLString:item.URLString]) {
			foundItem = item;
			*stop = YES;
		}
	}];
	return  foundItem;
}

- (void)downloadGIFForMovieRequest:(MovieQueueItem *)movieRequest
{
	
	NSDictionary *parameters = nil;
	
	void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
		[self postMovieFailedNotificationForRequest:movieRequest];
	};
	
	void (^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
		
		__block NSData *imageData = responseObject;

		if (imageData) {
			//NSLog(@"DOWNLOAD FULL GIF AND CONVERT %@", movieRequest.URLString);
			
			dispatch_async(_movieEncodeQueue, ^{ @autoreleasepool {
				
				// convert to MP4 file
				[self createMovieFromImageData:imageData forURLString:movieRequest.URLString progress:movieRequest.progress completion:^(BOOL success) {
					if (success) {
						[self postMovieUpdatedNotificationForRequest:movieRequest];
					} else {
						[self postMovieFailedNotificationForRequest:movieRequest];
					}
				}];
			}});
		} else {
			[self postMovieFailedNotificationForRequest:movieRequest];
		}
	};
	
    NSURLSessionDataTask *task = [_sessionManager GET:movieRequest.URLString parameters:parameters progress:NULL success:successBlock failure:failureBlock];
	
	// save pointer to download progress
	movieRequest.progress = [_sessionManager downloadProgressForTask:task];
	movieRequest.downloadstartTime = [NSDate date];
	
	// POST notification
	NSDictionary *userInfo = @{
							   YapImageManagerURLKey : movieRequest.URLString
							   };
	[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerMovieWillBeginDownloadingNotification object:self userInfo:userInfo];
	
}

- (void)downloadMP4ForMovieRequest:(MovieQueueItem *)movieRequest
{
	
	BOOL isGfycat = (movieRequest.gfycatId.length > 0);
	NSDictionary *parameters = nil;
	
	void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
		if (!isGfycat) {
			// try the origial GIF, if MP4 download failed, unless this was a gfycat URL (i.e. no GIF)
			[self downloadGIFForMovieRequest:movieRequest];
		} else {
			[self postMovieFailedNotificationForRequest:movieRequest];
		}
	};
	
	void (^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
		
		__block NSData *imageData = responseObject;
		if (imageData) {
			//NSLog(@"DOWNLOAD GFYCAT FOR %@", movieRequest.URLString);
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ @autoreleasepool {
				NSString *filename = [self movieFilenameForURLString:movieRequest.URLString];
				[imageData writeToFile:filename atomically:YES];
				// convert to MP4 file
				[self postMovieUpdatedNotificationForRequest:movieRequest];
			}});
		} else {
			if (!isGfycat) {
				// try the origial GIF, if MP4 download failed, unless this is a gfycat URL (i.e. no GIF)
				[self downloadGIFForMovieRequest:movieRequest];
			} else {
				[self postMovieFailedNotificationForRequest:movieRequest];
			}
		}
	};
	
    NSURLSessionDataTask *task = [_MP4SessionManager GET:movieRequest.movieURLString parameters:parameters progress:NULL success:successBlock failure:failureBlock];
	
	// save pointer to download progress
	movieRequest.progress = [_MP4SessionManager downloadProgressForTask:task];
	movieRequest.downloadstartTime = [NSDate date];
	
	// POST notification
	NSDictionary *userInfo = @{
							   YapImageManagerURLKey : movieRequest.URLString
							   };
	[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerMovieWillBeginDownloadingNotification object:self userInfo:userInfo];
	
}


- (void)checkGfycatForRequest:(MovieQueueItem *)movieRequest
{
	BOOL isGfycat = (movieRequest.gfycatId.length > 0);
	
	NSString *URLString = nil;
	NSDictionary *parameters = nil;
	
	if (isGfycat) {
		// if the link is Gfycat, fetch the MP4 URL using the gfycatId
		URLString = [NSString stringWithFormat:@"http://gfycat.com/cajax/get/%@", movieRequest.gfycatId];
	} else {
		// otherwise, check to see if a Gyfcat MP4 URL exists for this GIF
		//http://gfycat.com/cajax/checkUrl/
		NSString *escapedURLString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																										   (CFStringRef)movieRequest.URLString,
																										   NULL,
																										   CFSTR("!*'();:@&=+$,/?%#[]"),
																										   kCFStringEncodingUTF8));
		
		URLString = [NSString stringWithFormat:@"http://gfycat.com/cajax/checkUrl/%@", escapedURLString];
	}
	
	void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
		if (!isGfycat) {
			// try the origial GIF, if the Gfycat API failed
			[self downloadGIFForMovieRequest:movieRequest];
		} else {
			[self postMovieFailedNotificationForRequest:movieRequest];
		}
	};
	
	void (^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
		
		NSDictionary *response = responseObject;
		if (isGfycat) {
			response = [responseObject objectForKey:@"gfyItem"];
		}
		
		NSString *mp4URL = [response valueForKey:@"mp4Url"];
		if (mp4URL && mp4URL.length) {
			movieRequest.movieURLString = mp4URL;
			[self downloadMP4ForMovieRequest:movieRequest];
		} else {
			if (!isGfycat) {
				// try the origial GIF, if no MP4 URL
				if (movieRequest.URLString.length) {
					[self downloadGIFForMovieRequest:movieRequest];
				}
			} else {
				[self postMovieFailedNotificationForRequest:movieRequest];
			}
		}
	};
	
    [_gfycatSessionManager GET:URLString parameters:parameters progress:NULL success:successBlock failure:failureBlock];
	
}

- (void)processMovieQueue
{
	if (![self isReadyForMovieProcessing]) return;
	
	MovieQueueItem *movieRequest = [self nextMovieQueueItem];
	if (movieRequest) {
		[_movieRequests addObject:movieRequest];

		if (movieRequest.isImgurGifv) {
			NSMutableString *mp4URL = [movieRequest.URLString mutableCopy];

			NSRange foundRange = [movieRequest.URLString rangeOfString:@".gif" options:NSBackwardsSearch | NSCaseInsensitiveSearch | NSAnchoredSearch];
			if (foundRange.location != NSNotFound) {
				[mp4URL deleteCharactersInRange:foundRange];
				[mp4URL appendString:@".mp4"];
				movieRequest.movieURLString = mp4URL;
				[self downloadMP4ForMovieRequest:movieRequest];
			} else {
				// this should never happen
				[self checkGfycatForRequest:movieRequest];
			}
		} else {
			// check for gfycat MP4 and download directly, or download full GIF and convert to MP4
			[self checkGfycatForRequest:movieRequest];
		}
	}
}

- (void)postMovieUpdatedNotificationForRequest:(MovieQueueItem *)movieRequest
{
	dispatch_block_t block = ^{
		
		NSString *movieFilename = [self movieFilenameForURLString:movieRequest.URLString];
		
		NSDictionary *attributes = @{ YapImageManagerURLKey: movieRequest.URLString,
									  YapImageManagerMovieFilenameKey: movieFilename};
		
		[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerMovieUpdatedNotification
		                                                    object:self
		                                                  userInfo:attributes];
		// process next item
		[self removeQueuedMovieForURLString:movieRequest.URLString];
		movieRequest.progress = nil;
		[_movieRequests removeObject:movieRequest];
		[self processMovieQueue];
	};
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

- (void)postMovieFailedNotificationForRequest:(MovieQueueItem *)movieRequest
{
	dispatch_block_t block = ^{
		
		NSDictionary *attributes = @{ YapImageManagerURLKey: movieRequest.URLString };
		
		[[NSNotificationCenter defaultCenter] postNotificationName:YapImageManagerMovieFailedNotification
		                                                    object:self
		                                                  userInfo:attributes];
		// process next item
		[self removeQueuedMovieForURLString:movieRequest.URLString];
		movieRequest.progress = nil;
		[_movieRequests removeObject:movieRequest];
		[self processMovieQueue];
	};
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

- (NSProgress *)movieProgressForURLString:(NSString *)URLString
{
	
	MovieQueueItem *movieRequest = [self movieRequestForURLString:URLString];
	
	if (movieRequest) {
		return movieRequest.progress;
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cleanup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)removeExpiredImages
{

	dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {

		__block NSMutableArray *imageDeleteKeys = [NSMutableArray array];
		__block NSMutableArray *imageAttributeDeleteKeys = [NSMutableArray array];
				
		[[self attrbutesDatabaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
			[transaction enumerateKeysAndMetadataInCollection:kYapImageManagerImageAttributesCollection usingBlock:^(NSString *key, NSDate *created, BOOL *stop) {
				NSTimeInterval timeSince = -[created timeIntervalSinceNow];
				//NSLog(@"Check for expired image %@ (%0.2f)", key, timeSince);
				if (timeSince > EXPIRE_IMAGE_INTERVAL) {
					DDLogVerbose(@"** Remove expired image %@", key);
					[imageDeleteKeys addObject:key];
				}
				if (timeSince > EXPIRE_IMAGE_ATTRIBUTES_INTERVAL) {
					DDLogVerbose(@"** Remove expired attributes %@", key);
					[imageAttributeDeleteKeys addObject:key];
				}
			}];
		}];

		// remove expired images and images, images first so you never end up with images without attributes
		[[self backgroundDatabaseConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
			// remove images
			[transaction removeObjectsForKeys:imageDeleteKeys inCollection:kYapImageManagerImageCollection];
		} completionBlock:^{
			// remove image attributes after removing images has completed
			[[self backgroundAttributesDatabaseConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
				[transaction removeObjectsForKeys:imageAttributeDeleteKeys inCollection:kYapImageManagerImageAttributesCollection];
			} completionBlock:^{
				// DEBUG
				//[self validateDatabaseIntegrity];
			}];
		}];
				
		// DEBUG
		//[self validateDatabaseIntegrity];
		
	}});

}

- (void)validateDatabaseIntegrity
{
	__block NSMutableSet *imageKeys = [NSMutableSet set];
	__block NSMutableSet *imageAttributeKeys = [NSMutableSet set];
	
	[[self databaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		[transaction enumerateKeysAndMetadataInCollection:kYapImageManagerImageCollection usingBlock:^(NSString *key, id metadata, BOOL *stop) {
			[imageKeys addObject:key];
		}];
	}];
	
	[[self attrbutesDatabaseConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		[transaction enumerateKeysAndMetadataInCollection:kYapImageManagerImageAttributesCollection usingBlock:^(NSString *key, id metadata, BOOL *stop) {
			[imageAttributeKeys addObject:key];
		}];
	}];
	
	// there can be more image attributes than images, in the case of cancelled downloads since we pull size info out of the image header block
	if ([imageKeys isSubsetOfSet:imageAttributeKeys]) {
		DDLogInfo(@"- IMAGE CHECKSUM SUCCESS");
	} else {
		DDLogInfo(@"- IMAGE CHECKSUM FAILURE");
	}
}

- (void)removeExpiredMovies
{
	dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_async(concurrentQueue, ^{ @autoreleasepool {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		
		NSArray *dirContents = [fm contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
		for (NSString *tString in dirContents)
		{
			NSString *filename =[NSString stringWithFormat:@"%@/%@",documentsDirectoryPath,tString];
			if ([filename hasSuffix:@".mp4"]) {
				NSDictionary *attrs = [fm attributesOfItemAtPath:filename error:nil];
				if (attrs) {
					NSDate *created = (NSDate*)[attrs objectForKey: NSFileCreationDate];
					NSTimeInterval timeSince = -[created timeIntervalSinceNow];
					if (timeSince > EXPIRE_MP4_INTERVAL) {
						DDLogVerbose(@"Remove expired MP4 %@", tString);
						[fm removeItemAtPath:filename error:nil];
					}
				}
			}
		}
	}});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)reachabilityChanged:(NSNotification *)notification
{
	NSNumber *statusItem = [notification.userInfo objectForKey:AFNetworkingReachabilityNotificationStatusItem];
	AFNetworkReachabilityStatus status = [statusItem integerValue];
	
	if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi) {
		[self processImageQueue];
		[self processMovieQueue];
	}
}


@end
