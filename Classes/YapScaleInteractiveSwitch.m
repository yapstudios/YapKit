//
//  YapScaleInteractiveSwitch.m
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapScaleInteractiveSwitch.h"

@implementation YapScaleInteractiveSwitch

- (UIGestureRecognizer *)gesture
{
	UIPinchGestureRecognizer *gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	return gesture;
}

- (NSString *)transformKeyPath
{
	return @"transform.scale";
}

- (NSNumber *)valueFromGesture:(UIPinchGestureRecognizer *)gesture
{
	return @(gesture.scale);
}

- (NSNumber *)identityValue
{
	return @(1);
}

@end
