//
//  YapPanInteractiveSwitch.h
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapInteractiveSwitch.h"

@interface YapPanInteractiveSwitch : YapInteractiveSwitch

extern NSString *YapPanXAxisString;
extern NSString *YapPanYAxisString;

- (id)initWithReferenceView:(UIView *)view axis:(NSString *)xOrY;

//Will fail the switch if the gesture movement in the alternate axis is past a threshold - Default is NO
@property (nonatomic) BOOL directionLockEnabled;
@property (nonatomic) CGFloat directionLockThreshold; // defaults to 30 units

@end
