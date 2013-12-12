//
//  YapInteractiveSwitch.m
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapInteractiveSwitch.h"
#import "CALayer+Yapanimation.h"

@interface YapInteractiveSwitchContainer : UIView
@end
@implementation YapInteractiveSwitchContainer
@end

@interface YapInteractiveSwitch () <UIGestureRecognizerDelegate>
@end

@implementation YapInteractiveSwitch {
	
	YapInteractiveSwitchContainer *_containerView;
	
	//for calculating velocity
	CGFloat _lastTime;
	CGFloat _lastValue;
	CGFloat _velocity;
	
	CGFloat _velocityThreshold;
	CGFloat _baseTransformAmount;
	
	NSMutableArray *targetSelectors;
}

- (id)init
{
	self = [super init];
	if (self) {
		_velocityThreshold = 300;
		targetSelectors = [NSMutableArray array];
	}
	return self;
}

- (id)initWithReferenceView:(UIView *)view;
{
	self = [self init];
	if (self) {
		_referenceView = view;
		[self attachToView:_referenceView];
	}
	return self;
}

- (void)addTarget:(id)target restingAction:(SEL)restingAction activeAction:(SEL)activeAction
{
	NSString *restingSelectorString = NSStringFromSelector(restingAction);
	if (restingSelectorString == nil) {
		restingSelectorString = @"";
	}
	
	NSString *activeSelectorString = NSStringFromSelector(activeAction);
	if (activeSelectorString == nil) {
		activeSelectorString = @"";
	}
	
	[targetSelectors addObject:@{@"target": target, @"restingAction": restingSelectorString, @"activeAction": activeSelectorString}];
}

- (void)performRestingSelectors
{
	for (NSDictionary *d in targetSelectors) {
		NSString *restingSelectorString = [d objectForKey:@"restingAction"];
		if (restingSelectorString.length > 0) {
			id obj = [d objectForKey:@"target"];
			SEL action = NSSelectorFromString(restingSelectorString);
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[obj performSelector:action];
			#pragma clang diagnostic pop
		}
	}
}

- (void)performActiveSelectors
{
	for (NSDictionary *d in targetSelectors) {
		NSString *activeSelectorString = [d objectForKey:@"activeAction"];
		if (activeSelectorString.length > 0) {
			id obj = [d objectForKey:@"target"];
			SEL action = NSSelectorFromString(activeSelectorString);
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[obj performSelector:action];
			#pragma clang diagnostic pop
		}
	}
}

- (YapInteractiveSwitchContainer *)setupContainerViewForView:(UIView *)view
{
	//check to see if view is already in a switch container view
	YapInteractiveSwitchContainer *container = nil;
	if (![[view superview] isKindOfClass:[YapInteractiveSwitchContainer class]]) {
		//mirror the container view to the view
		container = [[YapInteractiveSwitchContainer alloc] initWithFrame:[view bounds]];
		container.layer.position = view.layer.position;
		container.layer.anchorPoint = view.layer.anchorPoint;
		//implant the view in this container
		view.layer.position = CGPointMake(container.bounds.size.width * view.layer.anchorPoint.x, container.bounds.size.height * view.layer.anchorPoint.y);
		[view.superview addSubview:container];
		[container addSubview:view];
	} else {
		container = (YapInteractiveSwitchContainer *)view.superview;
	}
	return container;
}

- (void)attachToView:(UIView *)view
{
	_containerView = [self setupContainerViewForView:view];
	UIGestureRecognizer *gesture = [self gesture];
	gesture.delegate = self;
	[_containerView addGestureRecognizer:gesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	BOOL shouldBegin = YES;
	if ([self.delegate respondsToSelector:@selector(yapInteractiveSwitchShouldBegin:)]) {
		shouldBegin = [self.delegate yapInteractiveSwitchShouldBegin:self];
	}
	return shouldBegin;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}


- (NSString *)transformKeyPath;
{
	return @"";
}

- (NSNumber *)valueFromGesture:(UIGestureRecognizer *)gesture
{
	return @(0);
}

- (NSNumber *)identityValue
{
	return @(0);
}

- (UIGestureRecognizer *)gesture
{
	return nil;
}

static float lerp(float p, float a, float b)
{
	return (a)+(b-a)*p;
}

- (NSDictionary *)lerpedPropertiesForPerformance:(YapInteractivePerformance *)performance percent:(CGFloat)percent
{
	NSDictionary *d = [performance toProperties];
	NSMutableDictionary *lerpDictionary = [NSMutableDictionary dictionary];
	for (NSString *key in d.allKeys) {
		CGFloat from = [[[performance fromProperties] objectForKey:key] doubleValue] || 0;
		CGFloat to = [[d objectForKey:key] doubleValue];
		[lerpDictionary setObject:@(lerp(percent, from, to)) forKey:key];
	}
	return lerpDictionary;
}

- (CGFloat)currentValueFromGesture:(UIGestureRecognizer *)gesture
{
	return [[self valueFromGesture:gesture] doubleValue] + _baseTransformAmount - [self identityValue].doubleValue;
}

- (CGFloat)percentCompleteOfGesture:(UIGestureRecognizer *)gesture
{
	return [self currentValueFromGesture:gesture] / [[self toValue] doubleValue];
}

- (CGFloat)percentInterpolatedForViewOfGesture:(UIGestureRecognizer *)gesture
{
	CGFloat currValue = [[gesture.view.layer.presentationLayer valueForKeyPath:[self transformKeyPath]] doubleValue];
	CGFloat percent = (currValue - [self identityValue].doubleValue) / ([self toValue].doubleValue - [self identityValue].doubleValue);
	return percent;
}

- (void)calculateVelocityWithCurrentTimeForGesture:(UIGestureRecognizer *)gesture
{
	CGFloat now = CACurrentMediaTime();
	CGFloat currentValue = [self currentValueFromGesture:gesture];
	CGFloat delta = currentValue - _lastValue;
	_velocity = delta / (now - _lastTime);
	_lastValue = currentValue;
	_lastTime = now;
}

- (BOOL)shouldTransitionForCurrentVelocity
{
	BOOL shouldTransition = [self toValue].doubleValue < 0 && _velocity < -_velocityThreshold;
	shouldTransition = shouldTransition || ([self toValue].doubleValue >= 0 && _velocity > _velocityThreshold);
	return shouldTransition;
}

- (BOOL)shouldTransitionToRestingStateForCurrentVelocity
{
	BOOL shouldTransition = [self toValue].doubleValue < 0 && _velocity > _velocityThreshold;
	shouldTransition = shouldTransition || ([self toValue].doubleValue >= 0 && _velocity < _velocityThreshold);
	return shouldTransition;
}

- (void)encodeBaselineValueForViewOfGesture:(UIGestureRecognizer *)gesture
{
	_baseTransformAmount = [[gesture.view.layer.presentationLayer valueForKeyPath:[self transformKeyPath]] doubleValue];
}

- (void)animatePerformersWithPercent:(CGFloat)percent
{
	for (YapInteractivePerformance *performer in self.performances) {
		NSDictionary *animationProperties = [self lerpedPropertiesForPerformance:performer percent:percent];
		//also animate the other actors in the performance
		for (UIView *coactor in performer.actors) {
			[coactor.layer animateKeyPathsAndValues:animationProperties];
		}
	}
}

- (void)setState:(YapInteractiveSwitchState)state
{
	//always do these things even if the state hasn't changed
	if (state == YapInteractiveSwitchStateOff) {
		//return to identity
		[_containerView.layer animateKeyPathsAndValues:@{[self transformKeyPath]: [self identityValue]}];
		[self animatePerformersWithPercent:0];
	} else if (state == YapInteractiveSwitchStateOn) {
		//go to 'to' value
		[_containerView.layer animateKeyPathsAndValues:@{[self transformKeyPath]: [self toValue]}];
		[self animatePerformersWithPercent:1.0];
	}
	
	
	//only do the following when the state has actually changed
	if (self.state != state) {
		_state = state;
		if ([self.delegate respondsToSelector:@selector(yapInteractiveSwitch:didChangeToState:)]) {
			[self.delegate yapInteractiveSwitch:self didChangeToState:self.state];
		}
		
		if (state == YapInteractiveSwitchStateOff) {
			//execute resting selectors
			[self performRestingSelectors];
		} else if (state == YapInteractiveSwitchStateOn) {
			//execute active selectors
			[self performActiveSelectors];
		}
		
	}
}

- (void)handleGesture:(UIGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan) {
		[self encodeBaselineValueForViewOfGesture:gesture];
		//delegate callback
		if ([self.delegate respondsToSelector:@selector(yapInteractiveSwitchDidBegin:)]) {
			[self.delegate yapInteractiveSwitchDidBegin:self];
		}
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged) {
		CGFloat percent = [self percentCompleteOfGesture:gesture];
		[gesture.view.layer animateKeyPathsAndValues:@{[self transformKeyPath]: @([self currentValueFromGesture:gesture])}];
		//start animating to the transform values
		[self animatePerformersWithPercent:percent];
		//keep a tab on velocity
		[self calculateVelocityWithCurrentTimeForGesture:gesture];
		//delegate callback
		if ([self.delegate respondsToSelector:@selector(yapInteractiveSwitch:didChangeToPercent:)]) {
			[self.delegate yapInteractiveSwitch:self didChangeToPercent:percent];
		}
	}
	
	if (gesture.state == UIGestureRecognizerStateEnded) {
		if ([self shouldTransitionForCurrentVelocity] || ([self percentInterpolatedForViewOfGesture:gesture] > 0.5 && ![self shouldTransitionToRestingStateForCurrentVelocity])) {
			self.state = YapInteractiveSwitchStateOn;
		} else {
			self.state = YapInteractiveSwitchStateOff;
		}
	}
}


@end
