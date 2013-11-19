
#import "CAKeyframeAnimation+Parametric.h"

@implementation CAKeyframeAnimation (Parametric)

//TODO: can we lerp from an arbitrary NSValue to another NSValue?
//Matrices? ??

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				 fromValue:(CGFloat)fromValue
				   toValue:(CGFloat)toValue
					 steps:(NSUInteger)steps;
{
	// get a keyframe animation to set up
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:path];
	// break the time into steps
	//  (the more steps, the smoother the animation)
	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:steps];
	CGFloat time = 0.0;
	CGFloat timeStep = 1.0 / (CGFloat)(steps - 1);
	for(NSUInteger i = 0; i < steps; i++) {
		CGFloat value = fromValue + block(time) * (toValue - fromValue);
		//TODO: support platforms on which CGFloat is a double
		[values addObject:[NSNumber numberWithFloat:value]];
		time += timeStep;
	}
	// set keyframes and we're done
	[animation setValues:values];
	return(animation);
}

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				 fromPoint:(CGPoint)fromValue
				   toPoint:(CGPoint)toValue
					 steps:(NSUInteger)steps;
{
	// get a keyframe animation to set up
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:path];
	// break the time into steps
	//  (the more steps, the smoother the animation)
	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:steps];
	CGFloat time = 0.0;
	CGFloat timeStep = 1.0 / (CGFloat)(steps - 1);
	for(NSUInteger i = 0; i < steps; i++) {
		CGFloat k = block(time);
		const CGPoint value = {
			fromValue.x + k * (toValue.x - fromValue.x),
			fromValue.y + k * (toValue.y - fromValue.y)
		};
		[values addObject:[NSValue valueWithCGPoint:value]];
		time += timeStep;
	}
	// set keyframes and we're done
	[animation setValues:values];
	return(animation);
}

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				 fromSize:(CGSize)fromValue
				   toSize:(CGSize)toValue
					 steps:(NSUInteger)steps;
{
	// get a keyframe animation to set up
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:path];
	// break the time into steps
	//  (the more steps, the smoother the animation)
	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:steps];
	CGFloat time = 0.0;
	CGFloat timeStep = 1.0 / (CGFloat)(steps - 1);
	for(NSUInteger i = 0; i < steps; i++) {
		CGFloat k = block(time);
		const CGSize value = {
			fromValue.width + k * (toValue.width - fromValue.width),
			fromValue.height + k * (toValue.height - fromValue.height)
		};
		[values addObject:[NSValue valueWithCGSize:value]];
		time += timeStep;
	}
	// set keyframes and we're done
	[animation setValues:values];
	return(animation);
}



@end
