//
//  YapRotationInteractiveSwitch.m
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapRotationInteractiveSwitch.h"

@implementation YapRotationInteractiveSwitch {
}

- (UIGestureRecognizer *)gesture
{
	UIRotationGestureRecognizer *gesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	return gesture;
}

- (NSString *)transformKeyPath
{
	return @"transform.rotation.z";
}

- (NSNumber *)valueFromGesture:(UIRotationGestureRecognizer *)gesture
{
	return @(gesture.rotation);
}

- (NSNumber *)identityValue
{
	return @(0);
}

@end
