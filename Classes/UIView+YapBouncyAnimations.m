//
//  UIView+YapBouncyAnimations.m
//  yap-iphone
//
//  Created by Trevor Stout on 4/26/13.
//  Copyright (c) 2013 Yap.tv, Inc. All rights reserved.
//

#import "UIView+YapBouncyAnimations.h"
//#import "CGRectUtils.h"
#import "CAAnimation+CurrentValue.h"
#import "CAKeyframeAnimation+Parametric.h"

#ifdef OW_BOUNCE
#import "OWBounceInterpolation.h"
#endif

// use 10.0 to slow down animation
#define SLOW_MO 1.0

@implementation UIView (YapBouncyAnimations)

// bounce view to a new frame
- (void)bounceToFrame:(CGRect)frame duration:(CFTimeInterval)duration
{
	duration *= SLOW_MO;
	
	if (CGRectEqualToRect(frame, self.frame)) return; // no animation required!

	CGPoint startPosition = (CGPoint) {
		.x = CGRectGetMidX(self.frame),
		.y = CGRectGetMidY(self.frame),		
	};

	CGPoint endPosition = (CGPoint) {
		.x = CGRectGetMidX(frame),
		.y = CGRectGetMidY(frame),
	};
		
	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setDisableActions:YES];

#ifdef OW_BOUNCE
	OWBounceInterpolation *spring = [[OWBounceInterpolation alloc] init];
	spring.tension = 180.0f;
	spring.friction = 18.0f;
#endif
	
	// remove any translation, if applicable
	CGPoint translation = (CGPoint) {
		.x = [[self.layer valueForKeyPath:@"transform.translation.x"] floatValue],
		.y = [[self.layer valueForKeyPath:@"transform.translation.y"] floatValue]
	};
	if (fabs(translation.x) > 0.0) {
#ifdef OW_BOUNCE
		//NSLog(@"remove translation x!");
		CAKeyframeAnimation *translationX = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
		translationX.duration = duration;
		spring.fromValue = translation.x;
		spring.toValue = 0.0;
		translationX.values = [spring arrayOfInterpolatedValues];
		translationX.calculationMode = kCAAnimationLinear;
		translationX.fillMode = kCAFillModeForwards;
		translationX.removedOnCompletion = YES;
		//NSLog(@"position.x from %f to %f", spring.fromValue, spring.toValue);
		[self.layer addAnimation:translationX forKey:@"translation.x"];
#else
		CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"transform.translation.x" fromValue:nil toValue:@(0.0) duration:duration];
		[self.layer addAnimation:animation forKey:@"transform.translation.x"];
#endif
	}
	
	if (fabs(translation.y) > 0.0) {
#ifdef OW_BOUNCE
		//NSLog(@"remove translation y!");
		CAKeyframeAnimation *translationY = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		translationY.duration = duration;
		spring.fromValue = translation.y;
		spring.toValue = 0.0;
		translationY.values = [spring arrayOfInterpolatedValues];
		translationY.calculationMode = kCAAnimationLinear;
		translationY.fillMode = kCAFillModeForwards;
		translationY.removedOnCompletion = YES;
		//NSLog(@"position.x from %f to %f", spring.fromValue, spring.toValue);
		[self.layer addAnimation:translationY forKey:@"transform.translation.y"];
#else
		CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"transform.translation.y" fromValue:nil toValue:@(0.0) duration:duration];
		[self.layer addAnimation:animation forKey:@"transform.translation.y"];
#endif
	}
	
	if (startPosition.x != endPosition.x) {
#ifdef OW_BOUNCE
		CAKeyframeAnimation *positionX = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
		positionX.duration = duration;
		//spring.fromValue = [[self.layer valueForKeyPath:@"position.x"] floatValue];
		spring.fromValue = startPosition.x - translation.x;
		spring.toValue = endPosition.x;
		positionX.values = [spring arrayOfInterpolatedValues];
		positionX.calculationMode = kCAAnimationLinear;
		positionX.fillMode = kCAFillModeForwards;
		positionX.removedOnCompletion = YES;
		//NSLog(@"position.x from %f to %f", spring.fromValue, spring.toValue);
		[self.layer addAnimation:positionX forKey:@"position.x"];
#else
		// TODO: for in flight animations, it is necessary to use nil for the from value to pick up the location and velocity from the presentation layer
		// this is causing Yap Music to glitch in the stacking controller when the view has translation; investigate
		//CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"position.x" fromValue:@(startPosition.x - translation.x) toValue:@(endPosition.x) duration:duration];
		CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"position.x" fromValue:nil toValue:@(endPosition.x) duration:duration];
		[self.layer addAnimation:animation forKey:@"position.x"];
#endif
	}
	if (startPosition.y != endPosition.y) {
#ifdef OW_BOUNCE
		CAKeyframeAnimation *positionY = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
		positionY.duration = duration;
		//spring.fromValue = [[viewController.view.layer valueForKeyPath:@"position.x"] floatValue];
		spring.fromValue = startPosition.y - translation.y;
		spring.toValue = endPosition.y;
		positionY.values = [spring arrayOfInterpolatedValues];
		positionY.calculationMode = kCAAnimationLinear;
		positionY.fillMode = kCAFillModeForwards;
		positionY.removedOnCompletion = YES;
		//NSLog(@"position.x from %f to %f", spring.fromValue, spring.toValue);
		[self.layer addAnimation:positionY forKey:@"position.y"];
#else
		//CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"position.y" fromValue:@(startPosition.y - translation.y) toValue:@(endPosition.y) duration:duration];
		CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"position.y" fromValue:nil toValue:@(endPosition.y) duration:duration];
		[self.layer addAnimation:animation forKey:@"position.y"];
#endif
	}
	
	// animate the z rotation, if not zero
	NSNumber *zRotation = [self.layer valueForKeyPath:@"transform.rotation.z"];
	if (zRotation && [zRotation floatValue] != 0.0) {
		// remove zRotation
		CAKeyframeAnimation *animation = [self bouncyAnimationForKeyPath:@"transform.rotation.z" fromValue:nil toValue:@(0.0) duration:duration];
		[self.layer addAnimation:animation forKey:@"transform.rotation.z"];
	}
	
	// animate the bounds if the size has changed
	if (!CGSizeEqualToSize(self.bounds.size, frame.size)) {
#ifdef OW_BOUNCE
		CAKeyframeAnimation *boundsWidth = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.width"];
		boundsWidth.duration = duration;
		spring.fromValue = self.frame.size.width;
		spring.toValue = frame.size.width;
		boundsWidth.values = [spring arrayOfInterpolatedValues];
		boundsWidth.calculationMode = kCAAnimationLinear;
		boundsWidth.fillMode = kCAFillModeForwards;
		boundsWidth.removedOnCompletion = YES;
		[self.layer addAnimation:boundsWidth forKey:@"bounds.size.width"];

		CAKeyframeAnimation *boundsHeight = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.height"];
		boundsHeight.duration = duration;
		spring.fromValue = self.frame.size.height;
		spring.toValue = frame.size.height;
		boundsHeight.values = [spring arrayOfInterpolatedValues];
		boundsHeight.calculationMode = kCAAnimationLinear;
		boundsHeight.fillMode = kCAFillModeForwards;
		boundsHeight.removedOnCompletion = YES;
		[self.layer addAnimation:boundsHeight forKey:@"bounds.size.height"];

#else
		CAKeyframeAnimation *boundsWidth = [self bouncyAnimationForKeyPath:@"bounds.size.width" fromValue:nil toValue:@(frame.size.width) duration:duration frequency:15.0 / SLOW_MO dampingRatio:0.7];
		[self.layer addAnimation:boundsWidth forKey:@"bounds.size.width"];

		CAKeyframeAnimation *boundsHeight = [self bouncyAnimationForKeyPath:@"bounds.size.height" fromValue:nil toValue:@(frame.size.height) duration:duration frequency:15.0 / SLOW_MO dampingRatio:0.7];
		[self.layer addAnimation:boundsHeight forKey:@"bounds.size.height"];
#endif


#ifdef SCALE_CONTENTS_RECT
		// animate the contents rect if the type is image and the aspect ratio has changed
		// NOTE: this is currently disable. Setting a UIImageView contentMode to UIViewContentModeScaleAspectFill
		// has a more natural feel than bouncing the aspect ratio
		if ([self isKindOfClass:[UIImageView class]]){
			UIImageView *imageView = (UIImageView *)self;
			CGRect fromRect = YapContentsRectMakeAspectFill(self.frame, imageView.image.size);
			CGRect toRect = YapContentsRectMakeAspectFill(frame, imageView.image.size);
			//NSLog(@"contents rect from %@ to %@", NSStringFromCGRect(fromRect), NSStringFromCGRect(toRect));
			
			if (!CGRectEqualToRect(fromRect, toRect)) {

				CAKeyframeAnimation *contentsRectX = [CAKeyframeAnimation animationWithKeyPath:@"contentsRect.origin.x"];
				contentsRectX.duration = duration;
				spring.fromValue = fromRect.origin.x;
				spring.toValue = toRect.origin.x;
				contentsRectX.values = [spring arrayOfInterpolatedValues];
				contentsRectX.calculationMode = kCAAnimationLinear;
				contentsRectX.fillMode = kCAFillModeForwards;
				contentsRectX.removedOnCompletion = YES;
				[self.layer addAnimation:contentsRectX forKey:@"contentsRect.origin.x"];

				CAKeyframeAnimation *contentsRectY = [CAKeyframeAnimation animationWithKeyPath:@"contentsRect.origin.y"];
				contentsRectY.duration = duration;
				spring.fromValue = fromRect.origin.y;
				spring.toValue = toRect.origin.y;
				contentsRectY.values = [spring arrayOfInterpolatedValues];
				contentsRectY.calculationMode = kCAAnimationLinear;
				contentsRectY.fillMode = kCAFillModeForwards;
				contentsRectY.removedOnCompletion = YES;
				[self.layer addAnimation:contentsRectY forKey:@"contentsRect.origin.y"];

				CAKeyframeAnimation *contentsRectWidth = [CAKeyframeAnimation animationWithKeyPath:@"contentsRect.size.width"];
				contentsRectWidth.duration = duration;
				spring.fromValue = fromRect.size.width;
				spring.toValue = toRect.size.width;
				contentsRectWidth.values = [spring arrayOfInterpolatedValues];
				contentsRectWidth.calculationMode = kCAAnimationLinear;
				contentsRectWidth.fillMode = kCAFillModeForwards;
				contentsRectWidth.removedOnCompletion = YES;
				[self.layer addAnimation:contentsRectWidth forKey:@"contentsRect.size.width"];
			
				CAKeyframeAnimation *contentsRectHeight = [CAKeyframeAnimation animationWithKeyPath:@"contentsRect.size.height"];
				contentsRectHeight.duration = duration;
				spring.fromValue = fromRect.size.height;
				spring.toValue = toRect.size.height;
				contentsRectHeight.values = [spring arrayOfInterpolatedValues];
				contentsRectHeight.calculationMode = kCAAnimationLinear;
				contentsRectHeight.fillMode = kCAFillModeForwards;
				contentsRectHeight.removedOnCompletion = YES;
				[self.layer addAnimation:contentsRectHeight forKey:@"contentsRect.size.height"];
				self.layer.contentsRect = toRect;
			
			}
		}
#endif
		self.layer.bounds = (CGRect) { .size = frame.size };
	
	}

	self.layer.position = (CGPoint) { .x = endPosition.x, .y = endPosition.y};
	self.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0);
	
	[CATransaction commit];
	
}


+ (NSNumber *)defaultValueForKeyPath:(NSString *)inKeyPath;
{
	NSNumber *classValue = [CALayer defaultValueForKey:inKeyPath];
	if (classValue) return classValue;
	
	if ([inKeyPath hasPrefix:@"transform.rotation"]) {
		return [NSNumber numberWithFloat:0.0f];
	} else if ([inKeyPath hasPrefix:@"transform.scale"]) {
		return [NSNumber numberWithFloat:1.0f];
	}
	return nil;
}

// use default spring values

- (CAKeyframeAnimation *)bouncyAnimationForKeyPath:(NSString *)inKeyPath
										 fromValue:(NSNumber *)inFromValue
										   toValue:(NSNumber *)inToValue
										  duration:(CFTimeInterval)duration
{
	return [self bouncyAnimationForKeyPath:inKeyPath fromValue:inFromValue toValue:inToValue duration:duration frequency:15.0 / SLOW_MO dampingRatio:0.7];
}

// if inFromValue is nil, will attempt to use current value, including in velocity for in flight animations

- (CAKeyframeAnimation *)bouncyAnimationForKeyPath:(NSString *)inKeyPath
										 fromValue:(NSNumber *)inFromValue
										   toValue:(NSNumber *)inToValue
										  duration:(CFTimeInterval)duration
										 frequency:(CGFloat)frequency
									  dampingRatio:(CGFloat)dampingRatio
{
	CALayer *presentationLayer = [self.layer presentationLayer];
	
	NSNumber *fromValue = inFromValue;
	if (!fromValue) fromValue = [presentationLayer valueForKeyPath:inKeyPath];
	if (!fromValue) fromValue = [self.layer valueForKeyPath:inKeyPath];
	if (!fromValue) fromValue = [UIView defaultValueForKeyPath:inKeyPath];
	
	NSNumber *toValue = inToValue;
	
	if (!toValue || !fromValue) {
		//NSLog(@"No animation possible for keyPath: %@. %@%@", inKeyPath, !toValue ? @"toValue is nil" : @"", !fromValue ? @"fromValue is nil" : @"");
		return nil;
	}
	
	NSAssert([fromValue isKindOfClass:[NSNumber class]], @"Must animate from a float");
	NSAssert([toValue isKindOfClass:[NSNumber class]], @"Must animate to a float");
	
	if (fabsf([toValue floatValue] - [fromValue floatValue]) < 0.0001f) {
		//NSLog(@"No animation necessary keyPath: %@. toValue = fromValue = %@", inKeyPath, toValue);
		return nil;
	}
	
	//NSLog(@"bouncy animation from %f to %f for %@", [fromValue floatValue], [toValue floatValue], inKeyPath);
	
	duration = duration > 0 ? duration : [CATransaction animationDuration];
	// TODO: check this calculation
	NSUInteger steps = 50 + 20 * duration;
		
	CAAnimation *existingAnimation =[(CALayer *)self.layer animationForKey:inKeyPath];
	NSValue *dVByDtCurrent = nil;
	if (existingAnimation) {
		dVByDtCurrent = [existingAnimation dValueByDtNow];
		//NSLog(@"current d %@ by dt : %@", inKeyPath, dVByDtCurrent);
	}
	
	//natural frequency
	const float omega = frequency * duration;
	
	//damping ratio
	const float zeta = dampingRatio;
	//ratio of natural damped frequency over natural frequency
	//ie beta * omega = natural damped frequency
	const float beta = sqrtf(1.f - zeta * zeta);
	
	// get current velocity
	CGFloat dV = [(NSNumber *)dVByDtCurrent floatValue];
	CGFloat v0 = dV * duration / ([toValue floatValue] - [fromValue floatValue]);
	
	const float x0 = 1.f;
	const float B = (zeta * omega * x0 + -v0) / (omega*beta);
	
	//NSLog(@"V0 : %f B : %f", v0, B);
	
	// bouncy timing function
	KeyframeParametricBlock bouncyTiming = ^(CGFloat t) {
		return (CGFloat)1.0f - expf(-zeta * omega * t) * (x0 * cosf(omega*beta * t) + B * sinf(omega*beta * t));
	};
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:inKeyPath
																	  function:bouncyTiming
																	 fromValue:[(NSNumber *)fromValue floatValue]
																	   toValue:[(NSNumber *)toValue floatValue]
																		 steps:steps];
	//TODO: investigate more carefully why this is required
	//animation.removedOnCompletion = NO;
	
	animation.duration = duration;
	animation.fillMode = kCAFillModeBoth;
	
	[animation setValue:[NSNumber numberWithDouble:CACurrentMediaTime()] forKey:DNAnimationStartedTimeKey];
	
	return animation;
}


@end
