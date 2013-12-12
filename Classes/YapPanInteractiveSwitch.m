//
//  YapPanInteractiveSwitch.m
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapPanInteractiveSwitch.h"

@implementation YapPanInteractiveSwitch {
	BOOL isXAxis;
}

NSString *YapPanXAxisString = @"x";
NSString *YapPanYAxisString = @"y";

- (id)initWithReferenceView:(UIView *)view axis:(NSString *)xOrY
{
	self = [self initWithReferenceView:view];
	if (self) {
		isXAxis = [xOrY isEqualToString:YapPanXAxisString];
		_directionLockEnabled = NO;
		_directionLockThreshold = 100;
	}
	return self;
}

- (UIGestureRecognizer *)gesture
{
	UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	return gesture;
}

- (NSString *)transformKeyPath
{
	return (isXAxis ? @"transform.translation.x" : @"transform.translation.y");
}

- (NSNumber *)valueFromGesture:(UIPanGestureRecognizer *)gesture
{
	return (isXAxis ? @([gesture translationInView:gesture.view.superview].x) : @([gesture translationInView:gesture.view.superview].y));
}

- (NSNumber *)identityValue
{
	return @(0);
}

- (BOOL)isInteractionValidForGesture:(UIPanGestureRecognizer *)gesture
{
	BOOL isValid = YES;
	if (_directionLockEnabled) {
		isValid = (isXAxis ? fabsf([gesture translationInView:gesture.view.superview].y) : fabsf([gesture translationInView:gesture.view.superview].x)) < _directionLockThreshold;
	}
	return isValid;
}

@end
