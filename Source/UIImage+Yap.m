//
//  UIImage+Yap.m
//
//  Created by Trevor Stout on 4/11/12.
//  Copyright (c) 2012 Yap.tv, Inc. All rights reserved.
//

#import "UIImage+Yap.h"

@implementation UIImage (Yap)

- (NSValue *)faceCentroidUsingFaceDetector:(CIDetector *)faceDetector
{
	CIImage *ciImage = [[CIImage alloc] initWithImage:self];
	NSArray *features = [faceDetector featuresInImage:ciImage];
	CGPoint faceCentroid;
	
	for (CIFaceFeature *f in features) {
		if (f.hasLeftEyePosition && f.hasRightEyePosition && f.hasMouthPosition) {
			faceCentroid.y = (f.leftEyePosition.y + f.mouthPosition.y) / 2.0;
			faceCentroid.x = (f.leftEyePosition.x + f.rightEyePosition.x) / 2.0;
			//NSLog(@"face center x = %f , y = %f", faceCentroid.x, faceCentroid.y);
			
			return [NSValue valueWithCGPoint:faceCentroid];
		}
	}
	return nil;
}

- (CGRect)aspectFillRectForRect:(CGRect)rect
{
	return [self aspectFillRectForRect:rect withFaceCentroid:nil];
}

- (CGRect)aspectFillRectForRect:(CGRect)rect withFaceCentroid:(NSValue *)faceCentroid
{
	CGPoint centroid = CGPointZero;
	if (faceCentroid)
		centroid = [faceCentroid CGPointValue];
		
	CGFloat targetAspectRatio = rect.size.width / rect.size.height;
	CGFloat imageAspectRatio = self.size.width / self.size.height;
	
	CGRect newRect = rect;
	
	// if approx the same, return target rect
	if (fabs(targetAspectRatio - imageAspectRatio) < .00000001) {
		// close enough! 
		CGFloat dx =  self.size.width - rect.size.width;
		CGFloat dy = self.size.height - rect.size.height;
		
		if (dx > 0 && dx < 5 && dy > 0 && dy < 5) {
			// if the image is relatively close to target, don't resize to avoid blurry images
			newRect = CGRectIntegral(CGRectInset(rect, -dx / 2.0, -dy / 2.0));
		}
		
		
	} else if (imageAspectRatio > targetAspectRatio) {
		// image is too wide, fix width, crop left/right
		newRect.size.width = roundf(rect.size.height * imageAspectRatio);
		newRect.origin.x -= roundf((newRect.size.width - rect.size.width) / 2.0);		
	} else if (imageAspectRatio < targetAspectRatio) {
		// image is too tall, fix height, crop top/bottom
		newRect.size.height = roundf(rect.size.width / imageAspectRatio);
		
		// check for face
		if (faceCentroid) {
			CGFloat newFaceCentroid = centroid.y * newRect.size.height / self.size.height;
			CGFloat originY =  newFaceCentroid - rect.size.height / 2.0;
			originY = fmaxf(0.0, originY);
			originY = fminf(originY, newRect.size.height - rect.size.height);
			newRect.origin.y -= originY;
		} else {
			newRect.origin.y -= roundf((newRect.size.height - rect.size.height) / 2.0);
		}
		
	}
	return newRect;
}

+ (CGSize)defaultPhotoVideoSizeForWidth:(CGFloat)maxWidth
{
	// default photo/video width is 4/3
	return (CGSize) { .width = maxWidth, .height = roundf(maxWidth * 0.75) };
	
}

+ (CGSize)aspectFitSizeForMaxWidth:(CGFloat)maxWidth withSize:(CGSize)actualSize {
    CGSize aspectFitSize = CGSizeZero;
    
	if (actualSize.width > 0.0)
		aspectFitSize = (CGSize) { maxWidth, roundf(maxWidth * (actualSize.height / actualSize.width)) };
    
    return aspectFitSize;
}

@end
