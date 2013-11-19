//
//  UIView+YapBouncyAnimations.h
//  yap-iphone
//
//  Created by Trevor Stout on 4/26/13.
//  Copyright (c) 2013 Yap.tv, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (YapBouncyAnimations)

- (void)bounceToFrame:(CGRect)frame duration:(CFTimeInterval)duration;

// return a bouncy keyframe animation for a view using default spring values
- (CAKeyframeAnimation *)bouncyAnimationForKeyPath:(NSString *)inKeyPath
										 fromValue:(NSNumber *)inFromValue
										   toValue:(NSNumber *)inToValue
										  duration:(CFTimeInterval)duration;

// return a bouncy keyframe animation for a view using custom spring values
- (CAKeyframeAnimation *)bouncyAnimationForKeyPath:(NSString *)inKeyPath
										 fromValue:(NSNumber *)inFromValue
										   toValue:(NSNumber *)inToValue
										  duration:(CFTimeInterval)duration
										 frequency:(CGFloat)frequency
									  dampingRatio:(CGFloat)dampingRatio;


@end
