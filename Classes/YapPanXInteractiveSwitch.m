//
//  YapPanXInteractiveSwitch.m
//  Yap Interactive Switch
//
//  Created by Ollie Wagner on 12/11/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapPanXInteractiveSwitch.h"

@implementation YapPanXInteractiveSwitch

- (UIGestureRecognizer *)gesture
{
	UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	return gesture;
}

- (NSString *)transformKeyPath
{
	return @"transform.translation.x";
}

- (NSNumber *)valueFromGesture:(UIPanGestureRecognizer *)gesture
{
	return @([gesture translationInView:gesture.view.superview].x);
}

- (NSNumber *)identityValue
{
	return @(0);
}

@end
