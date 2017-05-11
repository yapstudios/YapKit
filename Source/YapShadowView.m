//
//  YapShadowView.m
//
//  Created by Ollie Wagner on 4/4/15.
//  Copyright (c) 2015 Yap Studios LLC. All rights reserved.
//

#import "YapShadowView.h"


@implementation YapShadowView {
	UIImageView *_top;
	UIImageView *_left;
	UIImageView *_right;
	UIImageView *_bottom;
}

- (instancetype)initWithImage:(UIImage *)image;
{
	self = [self initWithFrame:CGRectZero];
	if (self) {
		self.userInteractionEnabled = NO;
		self.shadowImage = image;
		self.layer.allowsGroupOpacity = NO;
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		_top = [[UIImageView alloc] initWithFrame:CGRectZero];
		_left = [[UIImageView alloc] initWithFrame:CGRectZero];
		_right = [[UIImageView alloc] initWithFrame:CGRectZero];
		_bottom = [[UIImageView alloc] initWithFrame:CGRectZero];

		_top.contentMode = UIViewContentModeScaleToFill;

		[self addSubview:_top];
		[self addSubview:_left];
		[self addSubview:_right];
		[self addSubview:_bottom];

		_top.layer.allowsGroupOpacity = NO;
		_left.layer.allowsGroupOpacity = NO;
		_right.layer.allowsGroupOpacity = NO;
		_bottom.layer.allowsGroupOpacity = NO;
	}
	return self;
}

- (void)setShadowImage:(UIImage *)shadowImage
{
	_shadowImage = shadowImage;
	[self generateAssetsWithImage:_shadowImage];
	[self setNeedsLayout];
}

- (void)generateAssetsWithImage:(UIImage *)image
{
	UIImage *top, *left, *bottom, *right;
	[self edgesFromImage:image getTopPart:&top getLeftPart:&left getBottomPart:&bottom getRightPart:&right];

	_top.image = top;
	_left.image = left;
	_right.image = right;
	_bottom.image = bottom;
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	UIEdgeInsets capInsets = _shadowImage.capInsets;

	CGRect t = CGRectMake(-capInsets.left, -capInsets.top, self.bounds.size.width + capInsets.left + capInsets.right, capInsets.top);
	CGRect l = CGRectMake(-capInsets.left, 0, capInsets.left, self.bounds.size.height);
	CGRect r = CGRectMake(self.bounds.size.width, 0, capInsets.right, self.bounds.size.height);
	CGRect b = CGRectMake(-capInsets.left, self.bounds.size.height, self.bounds.size.width + capInsets.left + capInsets.right, capInsets.bottom);

	[_top setFrame:t];
	[_left setFrame:l];
	[_right setFrame:r];
	[_bottom setFrame:b];
}

- (void)edgesFromImage:(UIImage *)baseImage getTopPart:(UIImage **)outTop getLeftPart:(UIImage **)outLeft getBottomPart:(UIImage **)outBottom getRightPart:(UIImage **)outRight
{
	// Split the base image into its stretchable parts
	UIEdgeInsets insets = (UIEdgeInsets){
		.top = baseImage.capInsets.top * baseImage.scale,
		.left = baseImage.capInsets.left * baseImage.scale,
		.bottom = baseImage.capInsets.bottom * baseImage.scale,
		.right = baseImage.capInsets.right * baseImage.scale,
	};

	CGSize size = CGSizeMake(CGImageGetWidth(baseImage.CGImage), CGImageGetHeight(baseImage.CGImage));

	UIImage *(^clipImage)(UIImage *, CGRect, BOOL) = ^(UIImage *image, CGRect clipRect, BOOL stretchVertical) {

		CGImageRef imageRef = CGImageCreateWithImageInRect([baseImage CGImage], clipRect);
		UIEdgeInsets insets = UIEdgeInsetsZero;
		if (stretchVertical) {
			insets.top = (floor(clipRect.size.height / 2.0) - 1) / image.scale;
			insets.bottom = (ceil(clipRect.size.height / 2.0) - 1) / image.scale;
		} else {
			insets.left = (floor(clipRect.size.width / 2.0) - 1) / image.scale;
			insets.right = (ceil(clipRect.size.width / 2.0) - 1) / image.scale;
		}
		image = [[UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation] resizableImageWithCapInsets:insets];
		CGImageRelease(imageRef);


		return image;
	};

	CGRect t = CGRectMake(0, 0, size.width, insets.top);
	CGRect b = CGRectMake(0, size.height - insets.bottom, size.width, insets.bottom);
	CGRect l = CGRectMake(0, t.size.height, insets.left, size.height - t.size.height - b.size.height);
	CGRect r = CGRectMake(size.width - insets.right, t.size.height, insets.right, size.height - t.size.height - b.size.height);

	if (outTop) {
		*outTop = clipImage(baseImage, t, NO);
	}

	if (outBottom) {
		*outBottom = clipImage(baseImage, b, NO);
	}

	if (outLeft) {
		*outLeft = clipImage(baseImage, l, YES);
	}

	if (outRight) {
		*outRight = clipImage(baseImage, r, YES);
	}
}

@end
