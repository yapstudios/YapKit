//
//  TestAnimationController.h
//  BouncyTest
//
//  Created by Trevor Stout on 10/22/13.
//  Copyright (c) 2013 Trevor Stout. All rights reserved.
//

#import <Foundation/Foundation.h>

// use 10.0 to slow down animation
#define SLOW_MO 0.5

const static CGFloat kYapAnimationControllerDuration = SLOW_MO;

@interface YapAnimationController : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

@property (nonatomic, assign) BOOL interactionInProgress;

- (void)addPinchGestureRecognizerToController:(UIViewController *)viewController;

@end

@protocol YapAnimationControllerDelegate <NSObject>

// this is the transition view that will be used to animate;
// TODO: add a protocol for bouncy transitionView subview transitions
- (UIView *)animationController:(YapAnimationController *)animationController transitionViewToViewController:(id <YapAnimationControllerDelegate>)toViewController;
- (CGRect)animationController:(YapAnimationController *)animationController  transitionViewRectInView:(UIView *)view fromViewController:(id <YapAnimationControllerDelegate>)fromViewController;
- (CGRect)animationController:(YapAnimationController *)animationController  transitionViewRectInView:(UIView *)view toViewController:(id <YapAnimationControllerDelegate>)toViewController;

@optional

- (void)animationControllerPreparingForAnimationTransition:(YapAnimationController *)animationController;
- (void)animationControllerWillAnimateTransition:(YapAnimationController *)animationController;
- (void)animationControllerDidAnimateTransition:(YapAnimationController *)animationController;

@end