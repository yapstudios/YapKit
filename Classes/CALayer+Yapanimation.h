//
//  CALayer+Yapanimation.h
//  BouncyLayer
//
//  Created by Ollie Wagner on 11/13/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (Yapanimation)

struct YapanimationState {
	CGFloat value;
	CGFloat velocity;
};
typedef struct YapanimationState YapAnimationState;

- (void)setBouncyValue:(CGFloat)value forKeyPath:(NSString *)keyPath;
- (YapAnimationState)bouncyValueForKeyPath:(NSString *)keyPath;

//Animation Option Defaults
#define DEFAULT_TENSION   91
#define DEFAULT_FRICTION  11
#define DEFAULT_TIMESCALE 1
//Animation Options Keys
extern NSString const * YapanimationOptionTension;
extern NSString const * YapanimationOptionFriction;
extern NSString const * YapanimationOptionTimescale;

//Special transform keys/values
extern NSString const * YapanimationTransformKey;
extern NSString const * YapanimationTransformIdentity;

- (void)animateKeyPathsAndValues:(NSDictionary *)d;
- (void)animateKeyPathsAndValues:(NSDictionary *)d options:(NSDictionary *)options completion:(void (^)(BOOL finished))completion;

@end
