//
//  YapHTTPImageSessionManager.m
//  Feedworthy
//
//  Created by Trevor Stout on 12/9/13.
//  Copyright (c) 2013 Yap Studios LLC. All rights reserved.
//

#import "YapImageSessionManager.h"
#import "YapImageManager.h"

@class AFURLSessionManagerTaskDelegate;

@interface YapHTTPImageContext: NSObject

@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) int dataIndex;

@end

@implementation YapHTTPImageContext

// model object

@end

// TODO: currently accessing private variables; move to more complex subclassing
@interface AFURLSessionManagerTaskDelegate : NSObject
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSProgress *downloadProgress;
@end

@interface YapImageSessionManager (private)
- (AFURLSessionManagerTaskDelegate *)delegateForTask:(NSURLSessionTask *)task;
@end

@implementation YapImageSessionManager {
	NSCache *_imageAttributesCache;
	NSCache *_imageDownloadProgressCache;
	NSCache *_pendingGIFPreviews;

}

#pragma mark - NSURLSessionDataTaskDelegate

- (NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task {
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
    return [delegate downloadProgress];
}


- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
	BOOL isFirstPacket = (dataTask.countOfBytesReceived == data.length);

	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate.mutableData appendData:data];

	if (!_imageAttributesCache) {
		_imageAttributesCache = [[NSCache alloc] init];
		_imageAttributesCache.countLimit = 100;
		_imageDownloadProgressCache = [[NSCache alloc] init];
		_imageDownloadProgressCache.countLimit = MAX_SIMULTANEOUS_IMAGE_REQUESTS; // only need number of simultaneous requests
		_pendingGIFPreviews = [[NSCache alloc] init];
		_pendingGIFPreviews.countLimit = MAX_SIMULTANEOUS_IMAGE_REQUESTS;
	}
	
	NSString *key = dataTask.originalRequest.URL.absoluteString;
	
	NSDictionary *imageAttributes = [_imageAttributesCache objectForKey:key];

	// if the images attributes have not been found, scan the downloaded packets
	// Only scan first 250k bytes, as image attributes are unlikely to be found after that
	if (_shouldPreloadImageAttributes && !imageAttributes && (delegate.mutableData.length < 250000 || isFirstPacket)) {
		
		//NSLog(@"%d bytes downloaded for URL %@", (int) delegate.mutableData.length, key);

		YapHTTPImageContext *context = [YapHTTPImageContext new];
		context.URLString = key;
		context.data = delegate.mutableData;

		// clear any stale pending GIF previews
		if (isFirstPacket) {
			[_pendingGIFPreviews removeObjectForKey:key];
		}
		
		if ([self isJPEGImageFromContext:context]) {
			imageAttributes = [self JPEGImageAttributesFromContext:context];
			if (imageAttributes) {
				//NSLog(@"** found image attributes for %@ %@", context.URLString, imageAttributes);
				[_imageAttributesCache setObject:imageAttributes forKey:key];
				[self imageAttributesFound:imageAttributes forURLString:context.URLString];
			}
		} else if ([self isGIFImageFromContext:context]) {
			imageAttributes = [self GIFImageAttributesFromContext:context];
			if (imageAttributes) {
				//NSLog(@"** found GIF image attributes for %@ %@", context.URLString, imageAttributes);
				[_imageAttributesCache setObject:imageAttributes forKey:key];
				[self imageAttributesFound:imageAttributes forURLString:context.URLString];
				
				// flag this GIF to have a preview generated when the first frame is available after n bytes (est. by size * width)
				CGSize imageSize = [[YapImageManager sharedInstance] imageSizeForImageWithAttributes:imageAttributes];
				if (imageSize.width > 0.0 && imageSize.height > 0.0) {
					// make the GIF
					[_pendingGIFPreviews setObject:@(imageSize.width * imageSize.height) forKey:key];
				}
			}
		} else if ([self isPNGImageFromContext:context]) {
			imageAttributes = [self PNGImageAttributesFromContext:context];
			if (imageAttributes) {
				//NSLog(@"** found PNG image attributes for %@ %@", context.URLString, imageAttributes);
				[_imageAttributesCache setObject:imageAttributes forKey:key];
				[self imageAttributesFound:imageAttributes forURLString:context.URLString];
			}
		}
	}
	
	// check to see if first frame of GIF should be generated
	NSNumber *bytesRequiredToGenerateGIFPreview = [_pendingGIFPreviews objectForKey:key];
	if (_shouldPreloadGIFImageData && bytesRequiredToGenerateGIFPreview &&  dataTask.countOfBytesReceived >= bytesRequiredToGenerateGIFPreview.intValue) {
		[_pendingGIFPreviews removeObjectForKey:key];
		YapHTTPImageContext *context = [YapHTTPImageContext new];
		context.URLString = key;
		context.data = delegate.mutableData;
		NSData *imageData = [self GIFImageDataFromContext:context];
		if (imageData) {
			//NSLog(@"Preview for %@ generated in first %d of %d bytes", key, (int) dataTask.countOfBytesReceived, (int) dataTask.countOfBytesExpectedToReceive);

			dispatch_async(dispatch_get_main_queue(), ^{
				BOOL shouldCancelRequest = NO;
				if ([_delegate respondsToSelector:@selector(imageSessionManager:GIFImageDataFound:forURLString:shouldCancelRequest:)]) {
					[_delegate imageSessionManager:self GIFImageDataFound:imageData forURLString:key shouldCancelRequest:&shouldCancelRequest];
				}
				
				if (shouldCancelRequest)
					[dataTask cancel];
			});
		}
	}
	
	// handle download progress	
	if (dataTask.countOfBytesExpectedToReceive > 0) {
		CGFloat progress = (CGFloat) dataTask.countOfBytesReceived / (CGFloat) dataTask.countOfBytesExpectedToReceive;
		CGFloat roundedProgress = roundf(progress * 10.0); // round to 1/10
		
		// cleanup cache if at beginning or end of download
		if (isFirstPacket) {
			[_imageDownloadProgressCache removeObjectForKey:key];
		}
		
		NSNumber *priorProgress = [_imageDownloadProgressCache objectForKey:key];
		if (priorProgress && priorProgress.floatValue == roundedProgress) {
			// skip
		} else {
			[_imageDownloadProgressCache setObject:@(roundedProgress) forKey:key];
			delegate.downloadProgress.totalUnitCount = (int64_t) 10;
			delegate.downloadProgress.completedUnitCount = (int64_t) roundedProgress;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notification
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Handles posting notification to the main thread.
 **/
- (void)imageAttributesFound:(NSDictionary *)imageAttributes  forURLString:(NSString *)URLString
{
	dispatch_block_t block = ^{

		if ([_delegate respondsToSelector:@selector(imageSessionManager:imageAttributesFound:forURLString:)]) {
			[_delegate imageSessionManager:self imageAttributesFound:imageAttributes forURLString:URLString];
		}
	};
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark JPEG decoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (unsigned char)read_1_byte:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned char c = '\0';

	if (context.dataIndex >= context.data.length) {
		//NSLog(@"Premature EOF in JPEG file");
		*eof = YES;
		return c;
	}

	[context.data getBytes:&c range:NSMakeRange(context.dataIndex, 1)];
	context.dataIndex++;

	//NSLog(@"%d %02.2hhX", context.dataIndex, c);
	
	*eof = NO;
	return c;
}

/* Read 2 bytes, convert to unsigned int */
/* All 2-byte quantities in JPEG markers are MSB first */
- (unsigned int)read_2_bytes:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned int i;
	unsigned char c1, c2;
	
	c1 = [self read_1_byte:context eof:eof];
	c2 = [self read_1_byte:context eof:eof];
	i = (((unsigned int) c1) << 8) + ((unsigned int) c2);
	//NSLog(@"2 BYTES: %02.2X", i);
	return i;
}


/*
 * JPEG markers consist of one or more 0xFF bytes, followed by a marker
 * code byte (which is not an FF).  Here are the marker codes of interest
 * in this program.  (See jdmarker.c for a more complete list.)
 */

#define M_SOF0  0xC0		/* Start Of Frame N */
#define M_SOF1  0xC1		/* N indicates which compression process */
#define M_SOF2  0xC2		/* Only SOF0-SOF2 are now in common use */
#define M_SOF3  0xC3
#define M_SOF5  0xC5		/* NB: codes C4 and CC are NOT SOF markers */
#define M_SOF6  0xC6
#define M_SOF7  0xC7
#define M_SOF9  0xC9
#define M_SOF10 0xCA
#define M_SOF11 0xCB
#define M_SOF13 0xCD
#define M_SOF14 0xCE
#define M_SOF15 0xCF
#define M_SOI   0xD8		/* Start Of Image (beginning of datastream) */
#define M_EOI   0xD9		/* End Of Image (end of datastream) */
#define M_SOS   0xDA		/* Start Of Scan (begins compressed data) */
#define M_APP0	0xE0		/* Application-specific marker, type N */
#define M_APP12	0xEC		/* (we don't bother to list all 16 APPn's) */
#define M_COM   0xFE		/* COMment */


/*
 * Find the next JPEG marker and return its marker code.
 * We expect at least one FF byte, possibly more if the compressor used FFs
 * to pad the file.
 * There could also be non-FF garbage between markers.  The treatment of such
 * garbage is unspecified; we choose to skip over it but emit a warning msg.
 * NB: this routine must not be used after seeing SOS marker, since it will
 * not deal correctly with FF/00 sequences in the compressed image data...
 */

- (int)next_marker:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned char c;
	int discarded_bytes = 0;
	
	/* Find 0xFF byte; count and skip any non-FFs. */
	c = [self read_1_byte:context eof:eof];
	while (c != 0xFF && !*eof) {
		discarded_bytes++;
		c = [self read_1_byte:context eof:eof];
	}
	/* Get marker code byte, swallowing any duplicate FF bytes.  Extra FFs
	 * are legal as pad bytes, so don't count them in discarded_bytes.
	 */
	do {
		c = [self read_1_byte:context eof:eof];
	} while (c == 0xFF && !*eof);
	
	if (discarded_bytes != 0) {
		NSLog(@"Warning: garbage data found in JPEG file %@", context.URLString);
	}
	
	return c;
}


/*
 * Read the initial marker, which should be SOI.
 * For a JFIF file, the first two bytes of the file should be literally
 * 0xFF M_SOI.  To be more general, we could use next_marker, but if the
 * input file weren't actually JPEG at all, next_marker might read the whole
 * file and then return a misleading error message...
 */

- (int)first_marker:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned char c1, c2;
	
	c1 = [self read_1_byte:context eof:eof];
	c2 = [self read_1_byte:context eof:eof];

	if (c1 != 0xFF || c2 != M_SOI) {
		// not a JPEG file!
		*eof = YES;
	}
	return c2;
}


/*
 * Most types of marker are followed by a variable-length parameter segment.
 * This routine skips over the parameters for any marker we don't otherwise
 * want to process.
 * Note that we MUST skip the parameter segment explicitly in order not to
 * be fooled by 0xFF bytes that might appear within the parameter segment;
 * such bytes do NOT introduce new markers.
 */

- (void)skip_variable:(YapHTTPImageContext *)context eof:(BOOL *)eof
/* Skip over an unknown or uninteresting variable-length marker */
{
	unsigned int length;
	
	/* Get the marker parameter length count */
	length = [self read_2_bytes:context eof:eof];
	/* Length includes itself, so must be at least 2 */
	if (length < 2) {
		NSLog(@"Warning: erroneous JPEG marker length in %@", context.URLString);
		*eof = YES;
		return;
	}

	context.dataIndex += length - 2;
	if (context.dataIndex >= context.data.length) {
		//NSLog(@"Premature EOF in JPEG file");
		*eof = YES;
	}
}

- (NSString *)processForMarker:(int)marker
{
	NSString *process = nil;

	switch (marker) {
		case M_SOF0:	process = @"Baseline";  break;
		case M_SOF1:	process = @"Extended sequential";  break;
		case M_SOF2:	process = @"Progressive";  break;
		case M_SOF3:	process = @"Lossless";  break;
		case M_SOF5:	process = @"Differential sequential";  break;
		case M_SOF6:	process = @"Differential progressive";  break;
		case M_SOF7:	process = @"Differential lossless";  break;
		case M_SOF9:	process = @"Extended sequential, arithmetic coding";  break;
		case M_SOF10:	process = @"Progressive, arithmetic coding";  break;
		case M_SOF11:	process = @"Lossless, arithmetic coding";  break;
		case M_SOF13:	process = @"Differential sequential, arithmetic coding";  break;
		case M_SOF14:	process = @"Differential progressive, arithmetic coding"; break;
		case M_SOF15:	process = @"Differential lossless, arithmetic coding";  break;
		default:	process = @"Unknown";  break;
	}
	return process;
}

/*
 * Process a SOFn marker.
 * This code is only needed for the image dimensions...
 */

- (NSDictionary *)JPEGImageAttributesFromSOFn:(int)marker context:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	NSDictionary *imageAttributes = nil;
	unsigned int length;
	unsigned int image_height, image_width;
	unsigned char data_precision, num_components;
	int ci;
	
	length = [self read_2_bytes:context eof:eof];	/* usual parameter length count */
	
	data_precision = [self read_1_byte:context eof:eof];
	image_height = [self read_2_bytes:context eof:eof];
	image_width = [self read_2_bytes:context eof:eof];
	num_components = [self read_1_byte:context eof:eof];
	NSString *process = [self processForMarker:marker];
		
	
	if (length != (unsigned int) (8 + num_components * 3)) {
		NSLog(@"Warning: bogus SOF marker length in %@", context.URLString);
		*eof = YES;
	}
	
	if (*eof) return nil;
	
	for (ci = 0; ci < num_components; ci++) {
		[self read_1_byte:context eof:eof];	/* Component ID code */
		[self read_1_byte:context eof:eof];	/* H, V sampling factors */
		[self read_1_byte:context eof:eof];	/* Quantization table number */
	}

	if (!*eof) {
		imageAttributes = @{
							@"image_type": @"jpeg",
							@"image_height": @(image_height),
							@"image_width": @(image_width),
							@"data_precision": @(data_precision),
							@"color_components": @(num_components),
							@"process": process};
	}
	
	return imageAttributes;
}


/*
 * Parse the marker stream until SOS or EOI is seen;
 * display any COM markers.
 * While the companion program wrjpgcom will always insert COM markers before
 * SOFn, other implementations might not, so we scan to SOS before stopping.
 * If we were only interested in the image dimensions, we would stop at SOFn.
 * (Conversely, if we only cared about COM markers, there would be no need
 * for special code to handle SOFn; we could treat it like other markers.)
 */

- (NSDictionary *)JPEGImageAttributesFromContext:(YapHTTPImageContext *)context
{
	NSDictionary *imageAttributes = nil;
	int marker;
	BOOL eof = NO;
	context.dataIndex = 0; // reset initial state of context
	
	/* Expect SOI at start of file */
	if ([self first_marker:context eof:&eof] != M_SOI) {
		eof = YES;
	}
	
	/* Scan miscellaneous markers until we reach SOS. */
	while (!eof) {
		marker = [self next_marker:context eof:&eof];
		switch (marker) {
				/* Note that marker codes 0xC4, 0xC8, 0xCC are not, and must not be,
				 * treated as SOFn.  C4 in particular is actually DHT.
				 */
			case M_SOF0:		/* Baseline */
			case M_SOF1:		/* Extended sequential, Huffman */
			case M_SOF2:		/* Progressive, Huffman */
			case M_SOF3:		/* Lossless, Huffman */
			case M_SOF5:		/* Differential sequential, Huffman */
			case M_SOF6:		/* Differential progressive, Huffman */
			case M_SOF7:		/* Differential lossless, Huffman */
			case M_SOF9:		/* Extended sequential, arithmetic */
			case M_SOF10:		/* Progressive, arithmetic */
			case M_SOF11:		/* Lossless, arithmetic */
			case M_SOF13:		/* Differential sequential, arithmetic */
			case M_SOF14:		/* Differential progressive, arithmetic */
			case M_SOF15:		/* Differential lossless, arithmetic */
				imageAttributes = [self JPEGImageAttributesFromSOFn:marker context:context eof:&eof];
				return imageAttributes;
				break;
				
			case M_SOS:			/* stop before hitting compressed data */
				return imageAttributes;
				
			case M_EOI:			/* in case it's a tables-only JPEG stream */
				return imageAttributes;
				
			default:			/* Anything else just gets skipped */
				[self skip_variable:context eof:&eof];		/* we assume it has a parameter count... */
				break;
		}
	} /* end loop */
	return imageAttributes;
}

/*
 * Return YES if image is JPEG
 */

- (BOOL)isJPEGImageFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;
	context.dataIndex = 0; // reset initial state of context
	
	/* Expect SOI at start of file */
	if ([self first_marker:context eof:&eof] == M_SOI) {
		return YES;
	}
	return NO;
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark GIF decoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * Return YES if image is GIF89a or GIF87a
 */

- (BOOL)isGIFImageFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;
	context.dataIndex = 0; // reset initial state of context
	
	/* Expect SOI at start of file */
	if ([self first_GIF_marker:context eof:&eof]) {
		return YES;
	}
	return NO;
	
}

- (NSDictionary *)GIFImageAttributesFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;
	
	if ([self isGIFImageFromContext:context]) {
		unsigned int w = [self read_2_bytes_LSB:context eof:&eof];
		unsigned int h = [self read_2_bytes_LSB:context eof:&eof];
		
		if (!eof) {
			NSDictionary *imageAttributes = @{
											  @"image_type": @"gif",
											  @"image_height": @(h),
											  @"image_width": @(w)
											  };
			return imageAttributes;
		}
	}
	return nil;
}

- (NSData *)GIFImageDataFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;

	//NSLog(@"GIF BEGIN DECODE");
	
	if ([self isGIFImageFromContext:context]) {
		[self skip_n_bytes:context bytes:4 eof:&eof]; // logical screen descriptor, 7 bytes total
		unsigned char c = [self read_1_byte:context eof:&eof]; // packed fields
		[self skip_n_bytes:context bytes:2 eof:&eof];

		int colorTableSize = [self GIFColorTableSizeForColorTable:c];
		[self skip_n_bytes:context bytes:colorTableSize eof:&eof];     // skip color table
		
		unsigned char marker;
		while (!eof)
		{
			marker = [self read_1_byte:context eof:&eof];
			context.dataIndex--; // put back marker character
			
			if (marker == 0x3B)
			{
				// This is the end
				//NSLog(@"GIF END DECODE");
				break;
			}
			
			switch (marker)
			{
				case 0x21:
				{
					// Graphic Control Extension (#n of n)
					[self read_1_byte:context eof:&eof]; // skip first marker
					unsigned char extension = [self read_1_byte:context eof:&eof];
					context.dataIndex -= 2; // put back extension character and marker characters
					if (!eof) {
						switch (extension) {
							case 0xF9:
								[self skipGIFExtensionGraphicControl:context eof:&eof];
								break;
							case 0xFF:
								[self skipGIFExtensionApplication:context eof:&eof];
								break;
							case 0x01:
								[self skipGIFExtensionPlainText:context eof:&eof];
								break;
							case 0xFE:
								[self skipGIFExtensionComment:context eof:&eof];
								break;
								
							default:
								// error
								NSLog(@"GIF ERROR READING EXTENSION MARKER");
								eof = YES;
								break;
						}
					}
					break;
				}
				case 0x2C:
					// Image Descriptor (#n of n)
					[self skipGIFImageDescription:context eof:&eof];
					if (!eof) {
						// at this point we have the first image; insert EOF marker and return image data
						NSMutableData *imageData = [[NSMutableData alloc] init];
						[imageData appendData:[context.data subdataWithRange:NSMakeRange(0, context.dataIndex)]];
						unsigned char eof = 0x3B;
						[imageData appendBytes:&eof length:1];
												
						//NSLog(@"FOUND GIF FRAME FOR IMAGE %@ IN %d BYTES", context.URLString, (int) context.dataIndex);
						return imageData;
												
					}
					break;
				default:
					// error
					NSLog(@"GIF ERROR READING MARKER");
					eof = YES;
					break;
					
			}
		}
	}
	return nil;
	
}

- (void)skipGIFExtensionGraphicControl:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	//NSLog(@"GIF SKIP GIF EXTENSION");
	[self skip_n_bytes:context bytes:8 eof:eof];
}

- (void)skipGIFExtensionApplication:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	//NSLog(@"GIF SKIP APPLICATION EXTENSION");
	[self skip_n_bytes:context bytes:14 eof:eof];
	[self skipGIFDataBlocks:context eof:eof];
}

- (void)skipGIFExtensionPlainText:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	//NSLog(@"GIF SKIP PLAIN TEXT EXTENSION");
	[self skip_n_bytes:context bytes:15 eof:eof];
	[self skipGIFDataBlocks:context eof:eof];
}

- (void)skipGIFExtensionComment:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	//NSLog(@"GIF SKIP COMMENT EXTENSION");
	[self skip_n_bytes:context bytes:2 eof:eof];
	[self skipGIFDataBlocks:context eof:eof];
}

- (int)GIFColorTableSizeForColorTable:(unsigned char)c
{
	// get size of global color table
	if (c & 0x80)
	{
		int GIF_colorC = (c & 0x07);
		int GIF_colorS = 2 << GIF_colorC;
		return (3 * GIF_colorS);
	} else {
		return 0;
	}
}

- (void)skipGIFImageDescription:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	//NSLog(@"GIF SKIP IMAGE DESCRIPTION");
	[self skip_n_bytes:context bytes:9 eof:eof];
	unsigned char c = [self read_1_byte:context eof:eof];         // packed fields
	int colorTableSize = [self GIFColorTableSizeForColorTable:c];
	[self skip_n_bytes:context bytes:colorTableSize eof:eof];     // skip color table
	[self skip_n_bytes:context bytes:1 eof:eof];                  // skip lzw
	[self skipGIFDataBlocks:context eof:eof];
}

- (void)skipGIFDataBlocks:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	int totalBytes = 0;
	
	while (!*eof) {
		unsigned char bytes = [self read_1_byte:context eof:eof];
		if (bytes == 0x00) {
			//NSLog(@"GIF SKIP DATA BLOCKS (%d)", totalBytes);
			break;
		}
		totalBytes += bytes;
		[self skip_n_bytes:context bytes:bytes eof:eof];
	}
}

- (void)skip_n_bytes:(YapHTTPImageContext *)context bytes:(int)bytes eof:(BOOL *)eof
{
	context.dataIndex += bytes;
	if (context.dataIndex >= context.data.length) {
		*eof = YES;
	}
}

/* Read 2 bytes, convert to unsigned int */
/* All 2-byte quantities in GIF markers are LSB first */
- (unsigned int)read_2_bytes_LSB:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned int i;
	unsigned char c1, c2;
	
	c1 = [self read_1_byte:context eof:eof];
	c2 = [self read_1_byte:context eof:eof];
	i = (((unsigned int) c2) << 8) + ((unsigned int) c1);
	//NSLog(@"2 BYTES: %02.2X", i);
	return i;
}

- (BOOL)first_GIF_marker:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned char c1, c2, c3;
	unsigned char v1, v2, v3;
	
	c1 = [self read_1_byte:context eof:eof];
	c2 = [self read_1_byte:context eof:eof];
	c3 = [self read_1_byte:context eof:eof];

	v1 = [self read_1_byte:context eof:eof];
	v2 = [self read_1_byte:context eof:eof];
	v3 = [self read_1_byte:context eof:eof];
		
	if (c1 == 'G' && c2 == 'I' && c3 == 'F') {
		// not a JPEG file!
		return YES;
	}

	if (v1 == '8' && v2 == '9' && v3 == 'a') {
		// Version 89a
		return YES;
	}

	if (v1 == '8' && v2 == '7' && v3 == 'a') {
		// Version 87a... is this still used? Oh please... circa 1987
		return YES;
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark PNG decoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * Return YES if image is PNG
 */

- (BOOL)isPNGImageFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;
	context.dataIndex = 0; // reset initial state of context
	
	/* Expect SOI at start of file */
	if ([self first_PNG_marker:context eof:&eof]) {
		return YES;
	}
	return NO;
	
}

- (NSDictionary *)PNGImageAttributesFromContext:(YapHTTPImageContext *)context
{
	BOOL eof = NO;
	
	if ([self isPNGImageFromContext:context]) {
//		unsigned char skip;
//		skip = [self read_1_byte:context eof:&eof]; // byte 9
//		skip = [self read_1_byte:context eof:&eof]; // byte 10
//		skip = [self read_1_byte:context eof:&eof]; // byte 11
//		skip = [self read_1_byte:context eof:&eof]; // byte 12
		
		unsigned char c1 = [self read_1_byte:context eof:&eof];
		unsigned char c2 = [self read_1_byte:context eof:&eof];
		unsigned char c3 = [self read_1_byte:context eof:&eof];
		unsigned char c4 = [self read_1_byte:context eof:&eof];
		
		if (!eof && c1 == 'I' && c2 == 'H' && c3 == 'D' && c4 == 'R') { // IHDR

			unsigned long w = [self read_4_bytes:context eof:&eof];
			unsigned long h = [self read_4_bytes:context eof:&eof];

			if (!eof) {
				NSDictionary *imageAttributes = @{
												  @"image_type": @"png",
												  @"image_height": @(h),
												  @"image_width": @(w)
												  };
				return imageAttributes;
			}
		}
	}
	return nil;
}

- (unsigned long)read_4_bytes:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned long i;
	
	unsigned char c1 = [self read_1_byte:context eof:eof];
	unsigned char c2 = [self read_1_byte:context eof:eof];
	unsigned char c3 = [self read_1_byte:context eof:eof];
	unsigned char c4 = [self read_1_byte:context eof:eof];

	i = (((unsigned long) c1) << 24) + (((unsigned long) c2) << 16) + (((unsigned long) c3) << 8) + ((unsigned long) c4);
	return i;
}

- (BOOL)first_PNG_marker:(YapHTTPImageContext *)context eof:(BOOL *)eof
{
	unsigned char c1 = [self read_1_byte:context eof:eof];
	unsigned char c2 = [self read_1_byte:context eof:eof];
	unsigned char c3 = [self read_1_byte:context eof:eof];
	unsigned char c4 = [self read_1_byte:context eof:eof];
	unsigned char c5 = [self read_1_byte:context eof:eof];
	unsigned char c6 = [self read_1_byte:context eof:eof];
	unsigned char c7 = [self read_1_byte:context eof:eof];
	unsigned char c8 = [self read_1_byte:context eof:eof];

	if (c1 == 0x89 && c2 == 0x50 && c3 == 0x4E && c4 == 0x47 && c5 == 0x0D && c6 == 0X0A && c7 == 0X1A && c8 == 0x0A) {
		// PNG file!
		return YES;
	}
	
	return NO;
}

@end
