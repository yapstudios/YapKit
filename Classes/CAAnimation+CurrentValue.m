//
//  CAAnimation+CurrentValue.m
//  BetterBounce
//
//  Created by Andrew Pouliot on 6/18/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "CAAnimation+CurrentValue.h"

NSString *const DNAnimationStartedTimeKey = @"_dnBouncyStartTime";


@interface NSValue (NSValue_Lerp)
- (NSValue *)additiveIdentityOfSameType;
- (NSValue *)lerpWithValue:(NSValue *)inValue byAmount:(CGFloat)inAmount;
@end

@implementation NSValue (NSValue_Lerp)
- (NSValue *)additiveIdentityOfSameType;
{
	const char *valueType = [self objCType];
	if ( strcmp(valueType, @encode(CGPoint)) == 0 ) {
		return [NSValue valueWithCGPoint:CGPointZero];
	} else if ( strcmp(valueType, @encode(CGFloat)) == 0) {
		return [NSNumber numberWithFloat:0.0f];
	} else if ( strcmp(valueType, @encode(double)) == 0) {
		return [NSNumber numberWithDouble:0.0];
	} else {
		NSLog(@"Attempted to get additive identity for unsupported type: %s", valueType);
		return nil;
	}
}
- (NSValue *)lerpWithValue:(NSValue *)inValue byAmount:(CGFloat)k;
{
	if ( strcmp([inValue objCType], [self objCType]) != 0 ) {
		NSLog(@"Cannot lerp between incompatible types %s and %s!", [inValue objCType], [self objCType]);
		return nil;
	}
	
	const char *valueType = [self objCType];
	if ( strcmp(valueType, @encode(CGPoint)) == 0 ) {
		CGPoint fromValue = [self CGPointValue];
		CGPoint toValue = [inValue CGPointValue];
		const CGPoint value = {
			fromValue.x + k * (toValue.x - fromValue.x),
			fromValue.y + k * (toValue.y - fromValue.y)
		};
		return [NSValue valueWithCGPoint:value];
	} else if ( strcmp( valueType , @encode(CGFloat)) == 0 ) {
		CGFloat fromValue = [(NSNumber *)self floatValue];
		CGFloat toValue = [(NSNumber *)inValue floatValue];
		return [NSNumber numberWithFloat:fromValue + k * (toValue - fromValue)];
	} else if ( strcmp( valueType , @encode(double)) == 0 ) {
		double fromValue = [(NSNumber *)self doubleValue];
		double toValue = [(NSNumber *)inValue doubleValue];
		return [NSNumber numberWithDouble:fromValue + k * (toValue - fromValue)];
	}
	
	//TODO: numbers
	NSLog(@"Unable to lerp. Unsupported %s", [self objCType]);
	return nil;
}

- (NSValue *)diffWithValue:(NSValue *)other divideByAmount:(CGFloat)dt;
{
	if ( strcmp([other objCType], [self objCType]) != 0 ) {
		NSLog(@"Cannot diff div between incompatible types %s and %s!", [other objCType], [self objCType]);
		return nil;
	}
	
	const char *valueType = [self objCType];
	if ( strcmp(valueType, @encode(CGPoint)) == 0 ) {
		CGPoint a = [self CGPointValue];
		CGPoint b = [other CGPointValue];
		const CGPoint value = {
			(b.x - a.x) / dt,
			(b.y - a.y) / dt,
		};
		return [NSValue valueWithCGPoint:value];
	} else if ( strcmp( valueType , @encode(CGFloat)) == 0 ) {
		CGFloat fromValue = [(NSNumber *)self floatValue];
		CGFloat toValue = [(NSNumber *)other floatValue];
		return [NSNumber numberWithFloat:(toValue - fromValue) / dt];
	} else if ( strcmp( valueType , @encode(double)) == 0 ) {
		double fromValue = [(NSNumber *)self doubleValue];
		double toValue = [(NSNumber *)other doubleValue];
		return [NSNumber numberWithDouble:(toValue - fromValue) / dt];
	}
	//TODO: numbers
	NSLog(@"Unable to diff div. Unsupported %s", [self objCType]);
	return nil;
}


@end


@implementation CAKeyframeAnimation (CurrentValue)

- (NSValue *)dValueByDtAtTime:(CFTimeInterval)inTime;
{
	NSArray *values = self.values;
	CFTimeInterval duration = self.duration;
	//TODO: implement keyTimes!
	if ([self.calculationMode isEqualToString:kCAAnimationLinear] && !self.keyTimes && values.count > 1) {
		NSValue *before = values.count > 0 ? [values objectAtIndex:0] : nil;
		NSValue *after = nil;
		//The duration of one interval
		// in (a  b  c  d), this would be the time we're interpolating between a and b
		float intervalDuration = duration / (values.count - 1);
		for (int i=0; i<values.count; i++) {
			//TODO: implement all aspects of the CAMediaTiming protocol
			CFTimeInterval t = i * intervalDuration;
			//TODO: make this more efficient
			if (t < inTime) {
				before = [values objectAtIndex:i];
			}
			if (t >= inTime) {
				after = [values objectAtIndex:i];
				break;
			}
		}
		//If the time is after the end, no change
		if (!after) {
			return [before additiveIdentityOfSameType];
		}
		
		return [before diffWithValue:after divideByAmount:intervalDuration];
	} else {
		NSLog(@"-[%@ valueAtTime] not supported for calculation mode: %@ keyTimes: <%lu>", self.class, self.calculationMode, (unsigned long)self.keyTimes.count);
		return nil;
	}
}

// CGFloat => dV/dt
// CGPoint => CGPoint{dV.x/dt, dV.y/dt}
// CGSize  => CGSize{dV.width/dt, dV.height/dt}
// WTF??   => nil
- (id)dValueByDtNow;
{
	NSNumber *startedTime = [self valueForKey:DNAnimationStartedTimeKey];
	if (startedTime) {
		CFTimeInterval elapsed = CACurrentMediaTime() - [startedTime doubleValue];
		return [self dValueByDtAtTime:elapsed];
	}
	return nil;
}


@end

