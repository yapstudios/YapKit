//
//  CAAnimation+CurrentValue.h
//  BetterBounce
//
//  Created by Andrew Pouliot on 6/18/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

extern NSString *const DNAnimationStartedTimeKey;

@interface CAAnimation (CurrentValue)
- (id)dValueByDtNow;
@end