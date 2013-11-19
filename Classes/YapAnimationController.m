//
//  TestAnimationController.m
//  BouncyTest
//
//  Created by Trevor Stout on 10/22/13.
//  Copyright (c) 2013 Trevor Stout. All rights reserved.
//

#import "YapAnimationController.h"
#import "UIView+YapBouncyAnimations.h"

@implementation YapAnimationController {
    BOOL _shouldCompleteTransition;
    UIViewController *_viewController;
    CGFloat _startScale;
	CGPoint _startCenter;
	CGFloat _startAngle;
	
	id<UIViewControllerContextTransitioning> _context;
    UIViewController <YapAnimationControllerDelegate> *_fromViewController;
    UIViewController <YapAnimationControllerDelegate> *_toViewController;
	UIView *_transitionView;
	CGRect _transitionViewFromFrame;
	CGRect _transitionViewToFrame;
	CGFloat _percentComplete;
	
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
	return kYapAnimationControllerDuration;
}

#pragma mark -
#pragma mark UIViewControllerContextTransitioning

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
	// prepare for animation
	[self prepareAnimationTransition:transitionContext];
	
	NSTimeInterval duration = [self transitionDuration:transitionContext];

	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setCompletionBlock:^{
		// 6. inform the context of completion
		NSLog(@"CA ANIMATION COMPLETE %@", _transitionView);
		
		// notify animation delegate handlers
		if ([_toViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_toViewController animationControllerDidAnimateTransition:self];
		}
		if ([_fromViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_fromViewController animationControllerDidAnimateTransition:self];
		}

		[_transitionView removeFromSuperview];
	}];
	
	[_transitionView bounceToFrame:_transitionViewToFrame duration:duration];

    // 5. animate
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
						 _fromViewController.view.alpha = 0.0;
						 _toViewController.view.alpha = 1.0;
						 
						 // notify animation delegate handlers
						 if ([_toViewController respondsToSelector:@selector(animationControllerWillAnimateTransition:)]) {
							 [_toViewController animationControllerWillAnimateTransition:self];
						 }
						 if ([_fromViewController respondsToSelector:@selector(animationControllerWillAnimateTransition:)]) {
							 [_fromViewController animationControllerWillAnimateTransition:self];
						 }
					 } completion:^(BOOL finished) {
						 // completion handled by CATransaction completion block above
						 NSLog(@"VIEW ANIMATION COMPLETION");
						 _fromViewController.view.alpha = 1.0; // restore the alpha of the from view
						 _toViewController.view.alpha = 1.0; // restore the alpha of the from view
						 [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
					 }];
	[CATransaction commit];
}

#pragma mark -
#pragma mark UIViewControllerInteractiveTransitioning

- (void)addPinchGestureRecognizerToController:(UIViewController *)viewController
{
    _viewController = viewController;
    UIPinchGestureRecognizer *gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [viewController.view addGestureRecognizer:gesture];
}

// return agle of rotation between points, in radians
- (CGFloat)angleFromPoint1:(CGPoint)point1 toPoint2:(CGPoint)point2
{
	// TOA
	CGFloat opposite = point2.y - point1.y;
	CGFloat adjacent = point2.x - point1.x;
	
	
	CGFloat angle = M_PI / 2.0 + atanf(opposite/adjacent); // angle in radians
	if (adjacent >= 0.0) angle += M_PI; // for 360 degree rotation
	
	return angle;
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gestureRecognizer {
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            _startScale = gestureRecognizer.scale;
			_startCenter = [gestureRecognizer locationInView:_viewController.view];
			
			// TODO: convert touchpoints to an angle of rotation
			CGPoint point1 = [gestureRecognizer locationOfTouch:0 inView:_viewController.view];
			CGPoint point2 = [gestureRecognizer locationOfTouch:1 inView:_viewController.view];
			_startAngle = [self angleFromPoint1:point1 toPoint2:point2]; // angle in radians
			
            // 1. Start an interactive transition!
            self.interactionInProgress = YES;
			NSLog(@"POP DETAIL CONTROLLER (INTERACTIVE)");
			
			// TODO: make this work with a navigation controller or presented view controller
			// currently set to presented view controller
			[_viewController dismissViewControllerAnimated:YES completion:nil];
            //[_viewController.navigationController popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged: {
            // 2. compute the current position
            _percentComplete = fminf(1.0, 1.0 - gestureRecognizer.scale / _startScale);
            _shouldCompleteTransition = (_percentComplete > 0.5);

			CGPoint center = [gestureRecognizer locationInView:_viewController.view];
			CGPoint offset = (CGPoint) {
				.x = _startCenter.x - center.x,
				.y = _startCenter.y - center.y
			};

			CGPoint point1 = [gestureRecognizer locationOfTouch:0 inView:_viewController.view];
			CGPoint point2 = CGPointZero;
			CGFloat angle = 0.0;
			// make sure user doesn't lift one finger during gesture rec
			if ([gestureRecognizer numberOfTouches] > 1) {
				point2 = [gestureRecognizer locationOfTouch:1 inView:_viewController.view];
				angle = [self angleFromPoint1:point1 toPoint2:point2] - _startAngle; // angle in radians
				//NSLog(@"%f", angle);
				// update the animation controller
				[self updateInteractiveTransition:_percentComplete offset:offset angle:angle];
			} else {
				// cancel gesture rec if user lifts a finger!
				gestureRecognizer.enabled = NO;
			}
			         
            break;
        }
        case UIGestureRecognizerStateCancelled:
			if (gestureRecognizer.enabled == NO) {
				gestureRecognizer.enabled = YES; // re-enable the gesture rec, then continue w/UIGestureRecognizerStateEnded
			}
        case UIGestureRecognizerStateEnded:
            // 5. finish or cancel
            self.interactionInProgress = NO;
            if (!_shouldCompleteTransition || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                [self cancelInteractiveTransition];
            }
            else {
                [self finishInteractiveTransition];
            }
            break;
        default:
            break;
    }
}

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Maintain reference to context
    _context = transitionContext;
	
	// prepare for animation
	[self prepareAnimationTransition:transitionContext];
	
}

- (void)prepareAnimationTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // 1. obtain state from the context
    _toViewController = (UIViewController <YapAnimationControllerDelegate> *) [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    _fromViewController = (UIViewController <YapAnimationControllerDelegate> *) [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect finalFrame = [transitionContext finalFrameForViewController:_toViewController];
    
    // 2. obtain the container view
    UIView *containerView = [transitionContext containerView];
    
    // 3. set initial state
    _toViewController.view.frame = finalFrame;
	_toViewController.view.alpha = 0.0;
    
    // 4. add the view
    [containerView addSubview:_toViewController.view];
	
	// notify animation delegate handlers
	if ([_toViewController respondsToSelector:@selector(animationControllerPreparingForAnimationTransition:)]) {
		[_toViewController animationControllerPreparingForAnimationTransition:self];
	}
	if ([_fromViewController respondsToSelector:@selector(animationControllerPreparingForAnimationTransition:)]) {
		[_fromViewController animationControllerPreparingForAnimationTransition:self];
	}
	
	// get the transition view and to/from frame from the animation controller delegate
	_transitionViewFromFrame = [(id <YapAnimationControllerDelegate>) _fromViewController animationController:self transitionViewRectInView:containerView toViewController:_toViewController];
	_transitionViewToFrame = [(id <YapAnimationControllerDelegate>) _toViewController animationController:self transitionViewRectInView:containerView fromViewController:_fromViewController];
	_transitionView = [(id <YapAnimationControllerDelegate>) _fromViewController animationController:self transitionViewToViewController:_toViewController];
	_transitionView.frame = _transitionViewFromFrame;
	[containerView addSubview:_transitionView];
	
}

- (CGRect)lerpToFrameFromRect:(CGRect)fromRect toRect:(CGRect)toRect percentComplete:(CGFloat)percentComplete offset:(CGPoint)offset
{
	CGPoint fromCenter = (CGPoint) { CGRectGetMidX(fromRect), CGRectGetMidY(fromRect) };
	
	CGSize lerpToSize = (CGSize) {
		.width = fromRect.size.width + percentComplete * (toRect.size.width - fromRect.size.width),
		.height = fromRect.size.height + percentComplete * (toRect.size.height - fromRect.size.height)
	};

#define DISABLE_PINCH_ROTATE
#ifdef DISABLE_PINCH_ROTATE
	// use this to have the exit animation follow the same path as the intro animation
	CGPoint toCenter = (CGPoint) { CGRectGetMidX(toRect), CGRectGetMidY(toRect) };
	return (CGRect) {
		.origin.x = fromCenter.x + percentComplete * (toCenter.x - fromCenter.x) - lerpToSize.width / 2.0,
		.origin.y = fromCenter.y + percentComplete * (toCenter.y - fromCenter.y) - lerpToSize.height / 2.0,
		.size = lerpToSize
	};
#else
	// TODO: scale aspect ratio
	return (CGRect) {
		.origin.x = fromCenter.x - lerpToSize.width / 2.0 - offset.x,
		.origin.y = fromCenter.y - lerpToSize.height / 2.0 - offset.y,
		.size = lerpToSize
	};
#endif
}

-(void)updateInteractiveTransition:(CGFloat)percentComplete offset:(CGPoint)offset angle:(CGFloat)angle {
//	NSLog(@"UPDATE INTERACTIVE TRANSITION %f", percentComplete);
	CGFloat safePercentComplete = fmaxf(0.0, percentComplete); // do not exceed 0-100%
	_toViewController.view.alpha = safePercentComplete;
	_fromViewController.view.alpha = 1.0 - safePercentComplete;
	
    [_context updateInteractiveTransition:safePercentComplete];
	
	CGRect lerpToFrame = [self lerpToFrameFromRect:_transitionViewFromFrame toRect:_transitionViewToFrame percentComplete:percentComplete offset:offset];
	
#ifndef DISABLE_PINCH_ROTATE
	_transitionView.layer.transform = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0); // rotate on z to match pinch gesture
#endif
	_transitionView.layer.position = (CGPoint) {
		.x = CGRectGetMidX(lerpToFrame),
		.y = CGRectGetMidY(lerpToFrame),
	};
	_transitionView.layer.bounds = (CGRect) { .size = lerpToFrame.size };
	
	
}

-(void)cancelInteractiveTransition {
	NSLog(@"CANCEL INTERACTIVE TRANSITION");
	
	NSTimeInterval duration = kYapAnimationControllerDuration;
	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setCompletionBlock:^{
		// 6. inform the context of completion
		NSLog(@"CA ANIMATION COMPLETE %@", _transitionView);
		_transitionView.alpha = 0.0;

		[_context cancelInteractiveTransition];
		[_context completeTransition:NO];
				
		// notify animation delegate handlers
		// TODO: add cancel BOOL to delegate
		if ([_toViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_toViewController animationControllerDidAnimateTransition:self];
		}
		if ([_fromViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_fromViewController animationControllerDidAnimateTransition:self];
		}

		// cleanup
		[self cleanupInteractiveTransition];
		
	}];
	
	[_transitionView bounceToFrame:_transitionViewFromFrame duration:duration];
	
	[UIView animateWithDuration:duration animations:^{
		_toViewController.view.alpha = 0.0;
		_fromViewController.view.alpha = 1.0;
	} completion:^(BOOL finished) {
		NSLog(@"VIEW ANIMATION COMPLETION");
	}];
	[CATransaction commit];
}

-(void)finishInteractiveTransition {
	NSLog(@"FINISH INTERACTIVE TRANSITION");
	
	NSTimeInterval duration = kYapAnimationControllerDuration;
	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setCompletionBlock:^{
		// 6. inform the context of completion
		NSLog(@"CA ANIMATION COMPLETE %@", _transitionView);
		_transitionView.alpha = 0.0;

		[_context finishInteractiveTransition];
		[_context completeTransition:YES];
		
		// notify animation delegate handlers
		if ([_toViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_toViewController animationControllerDidAnimateTransition:self];
		}
		if ([_fromViewController respondsToSelector:@selector(animationControllerDidAnimateTransition:)]) {
			[_fromViewController animationControllerDidAnimateTransition:self];
		}

		// cleanup
		[self cleanupInteractiveTransition];
	
	}];
	
	[_transitionView bounceToFrame:_transitionViewToFrame duration:duration];
	
	[UIView animateWithDuration:duration animations:^{
		_toViewController.view.alpha = 1.0;
		_fromViewController.view.alpha = 0.0;
	} completion:^(BOOL finished) {
		NSLog(@"VIEW ANIMATION COMPLETION");
	}];
	[CATransaction commit];
}

- (void)cleanupInteractiveTransition
{
	// cleanup
	
	_fromViewController.view.alpha = 1.0; // restore the alpha of the from view
	_toViewController.view.alpha = 1.0; // restore the alpha of the from view	
	
	_context = nil;
	_toViewController = nil;
	_fromViewController = nil;
	
	[_transitionView removeFromSuperview];
	_transitionView = nil;
	
}

@end
