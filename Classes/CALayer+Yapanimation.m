//
//  CALayer+Yapanimation.m
//  BouncyLayer
//
//  Created by Ollie Wagner on 11/13/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "CALayer+Yapanimation.h"
#import "CAAnimation+DeltaTime.h"

@interface YapanimationStateStore : NSObject
@end

@implementation YapanimationStateStore {
	NSMutableArray *_values;
	NSMutableArray *_velocities;
}

- (id)init
{
	self = [super init];
	if (self) {
		_values = [NSMutableArray array];
		_velocities = [NSMutableArray array];
	}
	return self;
}

- (void)addValue:(CGFloat)value velocity:(CGFloat)velocity;
{
	[_values addObject:@(value)];
	[_velocities addObject:@(velocity)];
}

- (NSArray *)allValues;
{
	return _values;
}

- (NSArray *)allVelocities;
{
	return _velocities;
}

- (int)count
{
	return (int)_values.count;
}

- (YapAnimationState)stateForFrame:(int)frame;
{
	if (frame >= _values.count) {
		frame = (int)_values.count - 1;
	}
	return (YapAnimationState){.value = [[_values objectAtIndex:frame] doubleValue], .velocity = [[_velocities objectAtIndex:frame] doubleValue]};
}

@end

@implementation CALayer (Yapanimation)

CGFloat threshold = 0.03;

NSString * YapanimationOptionTension =   @"YapanimationOptionTension";
NSString * YapanimationOptionFriction =  @"YapanimationOptionFriction";
NSString * YapanimationOptionTimescale = @"YapanimationOptionTimescale";

NSString const * YapanimationTransformKey = @"YapanimationTransformKey";
NSString const * YapanimationTransformIdentity = @"YapanimationTransformIdentity";

- (NSString *)infoKeyForAnimationKey:(NSString *)keyPath
{
	return [NSString stringWithFormat:@"yapanimationInfo.%@", keyPath];
}

- (YapAnimationState)currentStateForKeyPath:(NSString *)keyPath
{
	//capture the model's state as a default return value (e.g. when there is no animation in flight)
	YapAnimationState state = (YapAnimationState){.value = [[self.presentationLayer valueForKeyPath:keyPath] doubleValue], .velocity = 0};
	CAAnimation *currentAnim = [self animationForKey:keyPath];
	//calculate the offset of the start time of the animation to now – derive frame from delta
	CFTimeInterval delta = [currentAnim deltaTime];
	if (delta) {
		int frameNum = delta * 60.f; //fps
		NSDictionary *d = [self valueForKey:[self infoKeyForAnimationKey:keyPath]];
		YapanimationStateStore *states = [d objectForKey:@"states"];
		//update the state
		state = [states stateForFrame:frameNum];
	}
	return state;
}

/* Packs up the states when a new animation is added. Uses key-value storage in the layer */
- (NSDictionary *)animDictionaryWithKeyPath:(NSString *)keyPath toValue:(CGFloat)value tension:(CGFloat)inTension friction:(CGFloat)inFriction timescale:(CGFloat)inTimescale
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	YapAnimationState currentState = [self currentStateForKeyPath:keyPath];
	YapanimationStateStore *states = [self keyStatesFromState:currentState toValue:value tension:inTension friction:inFriction timescale:inTimescale];
	[d setObject:states forKey:@"states"];
	[d setObject:@(states.count * 1 / 60.f) forKey:@"duration"];
	return d;
}

- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key animInfo:(NSDictionary *)info
{
	[self setValue:info forKey:[self infoKeyForAnimationKey:key]];
	[self addAnimation:anim forKey:key];
}

- (void)setBouncyValue:(CGFloat)value forKeyPath:(NSString *)keyPath tension:(CGFloat)inTension friction:(CGFloat)inFriction timescale:(CGFloat)inTimescale
{
	NSDictionary *d = [self animDictionaryWithKeyPath:keyPath toValue:value tension:inTension friction:inFriction timescale:inTimescale];
	YapanimationStateStore *states = [d objectForKey:@"states"];
	
	[self removeAnimationForKey:keyPath];
	CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:keyPath];
	anim.duration = [[d objectForKey:@"duration"] doubleValue];
	anim.values = [states allValues];
	anim.calculationMode = kCAAnimationLinear;
	anim.fillMode = kCAFillModeBoth;
	anim.removedOnCompletion = YES;
	[self setValue:@(value) forKeyPath:keyPath];
	[self addAnimation:anim forKey:keyPath animInfo:d];
}

- (void)setBouncyValue:(CGFloat)value forKeyPath:(NSString *)keyPath
{
	[self setBouncyValue:value forKeyPath:keyPath tension:DEFAULT_TENSION friction:DEFAULT_FRICTION timescale:DEFAULT_TIMESCALE];
}

//our state integrator
- (YapanimationStateStore *)keyStatesFromState:(YapAnimationState)state toValue:(CGFloat)to tension:(CGFloat)inTension friction:(CGFloat)inFriction timescale:(CGFloat)inTimescale {
	YapanimationStateStore *states = [[YapanimationStateStore alloc] init];
	
	//acceleration function for a spring
	accelBlock bouncyAccelerationBlock = ^(CGFloat x, CGFloat v, CGFloat dt) {
		return (CGFloat)(-inTension * x - inFriction * v);
	};
	
	while (states.count < 3000 /* sanity cap */ && (fabs(state.value - to) > threshold || fabs(state.velocity) > threshold || states.count == 0)) { //while in motion
		CGFloat offset = state.value - to;
		CGFloat currentValue = state.value;
		state = rk4((YapAnimationState){.value = offset, .velocity = state.velocity}, bouncyAccelerationBlock, 1 / 60.f * inTimescale);
		CGFloat delta = state.value - offset;
		state.value = currentValue + delta;
		[states addValue:state.value velocity:state.velocity];
	}
	//add the final state
	YapAnimationState finalState = (YapAnimationState){.value = to, .velocity = 0};
	[states addValue:finalState.value velocity:finalState.velocity];

	return states;
}

//unpacker for struct properties like bounds, contentsRect, position, etc…
//this method is not complete - we need to scrub CALayer and make sure all of the properties are covered
- (NSDictionary *)unpackedDictionaryFromDictionary:(NSDictionary *)dictionary
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	BOOL needsSubsequentUnpacking = NO;
	for (NSString *keyPath in dictionary) {
		
		BOOL keyIsRect         = ([keyPath isEqualToString:@"bounds"] || [keyPath isEqualToString:@"contentsRect"] || [keyPath isEqualToString:@"contentsCenter"]);
		BOOL keyIsPoint        = ([keyPath isEqualToString:@"position"] || [keyPath isEqualToString:@"anchorPoint"]);
		BOOL keyIsPoint3D      = ([keyPath isEqualToString:@"transform.translation"] || [keyPath isEqualToString:@"transform.rotation"] || [keyPath isEqualToString:@"transform.scale"]);
		BOOL keyIsFrame        = ([keyPath isEqualToString:@"frame"]);
		BOOL keyIsYapTransform = ([keyPath isEqualToString:(NSString *)YapanimationTransformKey]);
		
		if (keyIsRect) {
			CGRect r = [[dictionary objectForKey:keyPath] CGRectValue];
			[d setObject:@(r.origin.x) forKey:[NSString stringWithFormat:@"%@.origin.x", keyPath]];
			[d setObject:@(r.origin.y) forKey:[NSString stringWithFormat:@"%@.origin.y", keyPath]];
			[d setObject:@(r.size.width) forKey:[NSString stringWithFormat:@"%@.size.width", keyPath]];
			[d setObject:@(r.size.height) forKey:[NSString stringWithFormat:@"%@.size.height", keyPath]];
			
		} else if (keyIsPoint) {
			CGPoint p = [[dictionary objectForKey:keyPath] CGPointValue];
			[d setObject:@(p.x) forKey:[NSString stringWithFormat:@"%@.x", keyPath]];
			[d setObject:@(p.y) forKey:[NSString stringWithFormat:@"%@.y", keyPath]];
			
		} else if (keyIsPoint3D) {
			CGFloat p = [[dictionary objectForKey:keyPath] doubleValue];
			[d setObject:@(p) forKey:[NSString stringWithFormat:@"%@.x", keyPath]];
			[d setObject:@(p) forKey:[NSString stringWithFormat:@"%@.y", keyPath]];
			[d setObject:@(p) forKey:[NSString stringWithFormat:@"%@.z", keyPath]];
			
		} else if (keyIsFrame) {
			CGRect frame = [[dictionary objectForKey:keyPath] CGRectValue];
			CGRect bounds = (CGRect){.size = frame.size};
			CGPoint position = (CGPoint){.x = frame.origin.x + frame.size.width * self.anchorPoint.x, .y = frame.origin.y + frame.size.height * self.anchorPoint.y};
			[d setObject:[NSValue valueWithCGRect:bounds] forKey:@"bounds"];
			[d setObject:[NSValue valueWithCGPoint:position] forKey:@"position"];
			
			needsSubsequentUnpacking = YES;
			
		} else if (keyIsYapTransform) {
			if ([[dictionary objectForKey:keyPath] isEqualToString:(NSString *)YapanimationTransformIdentity]) {
				[d setObject:@(0) forKey:@"transform.translation"];
				[d setObject:@(0) forKey:@"transform.rotation"];
				[d setObject:@(1) forKey:@"transform.scale"];
				
				needsSubsequentUnpacking = YES;
			}
		} else {
			[d setObject:[dictionary objectForKey:keyPath] forKey:keyPath];
		}
	}
	return (needsSubsequentUnpacking ? [self unpackedDictionaryFromDictionary:d] : d);
}

//api goodness
- (void)animateKeyPathsAndValues:(NSDictionary *)d
{
	[self animateKeyPathsAndValues:d options:nil completion:NULL];
}

- (void)animateKeyPathsAndValues:(NSDictionary *)d tension:(CGFloat)inTension friction:(CGFloat)inFriction timescale:(CGFloat)inTimeScale
{
	for (NSString *keyPath in d.allKeys) {
		[self setBouncyValue:[[d objectForKey:keyPath] doubleValue] forKeyPath:keyPath tension:inTension friction:inFriction timescale:inTimeScale];
	}
}

- (void)animateKeyPathsAndValues:(NSDictionary *)d options:(NSDictionary *)options completion:(void (^)(BOOL finished))completion;
{
	
	[CATransaction begin];
	[CATransaction setCompletionBlock:^{
		if (completion) {
			completion(YES);
		}
	}];
	
	//set options
	CGFloat tension = DEFAULT_TENSION;
	CGFloat friction = DEFAULT_FRICTION;
	CGFloat timescale = DEFAULT_TIMESCALE;
	
	if (options && [options valueForKey:YapanimationOptionTension])
		tension = [[options valueForKey:YapanimationOptionTension] doubleValue];
	
	if (options && [options valueForKey:YapanimationOptionFriction])
		friction = [[options valueForKey:YapanimationOptionFriction] doubleValue];
	
	if (options && [options valueForKey:YapanimationOptionTimescale])
		timescale = [[options valueForKey:YapanimationOptionTimescale] doubleValue];
	
	//unpack compound values
	d = [self unpackedDictionaryFromDictionary:d];
	//send to our bouncy system
	[self animateKeyPathsAndValues:d tension:tension friction:friction timescale:timescale];
	
	[CATransaction commit];
}

- (YapAnimationState)bouncyValueForKeyPath:(NSString *)keyPath;
{
	return [self currentStateForKeyPath:keyPath];
}

#pragma mark Helpers

typedef CGFloat(^accelBlock)(CGFloat value, CGFloat velocity, CGFloat timestep);

YapAnimationState rk4(YapAnimationState state, accelBlock a, CGFloat dt) {
	//INPUT : position, velocity, accelFunc, timestep
	//OUTPUT: value, velocity
	CGFloat x = state.value;
	CGFloat v = state.velocity;
	
	CGFloat x1 = x;
	CGFloat v1 = v;
	CGFloat a1 = a(x1, v1, 0);
	
	CGFloat x2 = x + 0.5 * v1 * dt;
	CGFloat v2 = v + 0.5 * a1 * dt;
	CGFloat a2 = a(x2, v2, dt / 2);
	
	CGFloat x3 = x + 0.5 * v2 * dt;
	CGFloat v3 = v + 0.5 * a2 * dt;
	CGFloat a3 = a(x3, v3, dt / 2);
	
	CGFloat x4 = x + v3 * dt;
	CGFloat v4 = v + a3 * dt;
	CGFloat a4 = a(x4, v4, dt);
	
	x = x + (dt / 6) * (v1 + 2 * v2 + 2 * v3 + v4);
	v = v + (dt / 6) * (a1 + 2 * a2 + 2 * a3 + a4);
	
	return (YapAnimationState){
		.value = x,
		.velocity = v
	};
}

@end
