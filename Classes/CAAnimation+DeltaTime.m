//
//  CAAnimation+DeltaTime.m
//  Yapanimation
//
//  Created by Ollie Wagner on 11/15/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "CAAnimation+DeltaTime.h"

@implementation CAAnimation (DeltaTime)

- (CFTimeInterval)deltaTime
{
	CFTimeInterval startTime = [[self valueForKey:@"beginTime"] doubleValue];
	CFTimeInterval now = CACurrentMediaTime();
	return (startTime ? now - startTime : 0);
}

@end
