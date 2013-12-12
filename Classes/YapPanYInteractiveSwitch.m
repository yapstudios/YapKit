//
//  YapPanInteractiveSwitch.m
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapPanYInteractiveSwitch.h"

@implementation YapPanYInteractiveSwitch

- (UIGestureRecognizer *)gesture
{
	UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	return gesture;
}

- (NSString *)transformKeyPath
{
	return @"transform.translation.y";
}

- (NSNumber *)valueFromGesture:(UIPanGestureRecognizer *)gesture
{
	return @([gesture translationInView:gesture.view.superview].y);
}

- (NSNumber *)identityValue
{
	return @(0);
}

@end
