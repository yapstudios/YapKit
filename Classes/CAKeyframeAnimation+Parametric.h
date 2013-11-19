
#import <QuartzCore/QuartzCore.h>

// Derived from: http://stackoverflow.com/questions/5161465/how-to-create-custom-easing-function-with-core-animation/5958381#5958381
// Whose License is http://creativecommons.org/licenses/by-sa/3.0/ according to Stack Overflow at time of access

// this should be a function that takes a time value between 
//  0.0 and 1.0 (where 0.0 is the beginning of the animation
//  and 1.0 is the end) and returns a scale factor where 0.0
//  would produce the starting value and 1.0 would produce the
//  ending value
typedef CGFloat (^KeyframeParametricBlock)(CGFloat t);

@interface CAKeyframeAnimation (Parametric)

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				 fromValue:(CGFloat)fromValue
				   toValue:(CGFloat)toValue
					 steps:(NSUInteger)steps;

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				 fromPoint:(CGPoint)fromValue
				   toPoint:(CGPoint)toValue
					 steps:(NSUInteger)steps;

+ (id)animationWithKeyPath:(NSString *)path 
				  function:(KeyframeParametricBlock)block
				  fromSize:(CGSize)fromValue
					toSize:(CGSize)toValue
					 steps:(NSUInteger)steps;

@end