//
//  UIImage+Yap.h
//
//  Created by Trevor Stout on 4/11/12.
//  Copyright (c) 2012 Yap.tv, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Yap)
// returns a rect with the image positioned for an aspect fill
// caller needs to call clipToRect before drawing image with the aspectFillRect
- (CGRect)aspectFillRectForRect:(CGRect)rect;
- (CGRect)aspectFillRectForRect:(CGRect)rect withFaceCentroid:(NSValue *)faceCentroid;
- (NSValue *)faceCentroidUsingFaceDetector:(CIDetector *)faceDetector;
+ (CGSize)defaultPhotoVideoSizeForWidth:(CGFloat)maxWidth;
+ (CGSize)aspectFitSizeForMaxWidth:(CGFloat)maxWidth withSize:(CGSize)actualSize;

@end
