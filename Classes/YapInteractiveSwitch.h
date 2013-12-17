//
//  YapInteractiveSwitch.h
//  YapBouncySwitch
//
//  Created by Ollie Wagner on 12/9/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapInteractivePerformance.h"

@class YapInteractiveSwitch;

typedef enum {
	YapInteractiveSwitchStateOff,
	YapInteractiveSwitchStateOn
} YapInteractiveSwitchState;

@protocol YapInteractiveSwitchDelegate <NSObject>
@optional
- (BOOL)yapInteractiveSwitchShouldBegin:(YapInteractiveSwitch *)theSwitch;
- (void)yapInteractiveSwitchDidBegin:(YapInteractiveSwitch *)theSwitch;
- (void)yapInteractiveSwitch:(YapInteractiveSwitch *)theSwitch didChangeToPercent:(CGFloat)percent;
- (void)yapInteractiveSwitch:(YapInteractiveSwitch *)theSwitch didChangeToState:(YapInteractiveSwitchState)state;
@end

@interface YapInteractiveSwitch : NSObject

- (id)initWithReferenceView:(UIView *)view;

@property (readonly) UIView *referenceView;
@property (nonatomic, weak) id <YapInteractiveSwitchDelegate> delegate;

//YapInteractivePerformance Objects
@property (nonatomic,retain) NSArray *performances;

- (void)addTarget:(id)target restingAction:(SEL)restingAction activeAction:(SEL)activeAction;

//subclasses must implement these things
- (UIGestureRecognizer *)gesture;

// TODO: Ollie remove/update these.
//- (NSArray *)propertyKeyPaths;
//- (NSNumber *)valueFromGesture:(UIGestureRecognizer *)gesture forKeyPath:(NSString *)keyPath;

- (NSNumber *)identityValue;
//optional - used for cancelling a switch when the gesture finishes
- (BOOL)isInteractionValidForGesture:(UIGestureRecognizer *)gesture;

//never call this directly - this is the selector that subclasses should attach to their gesture
- (void)handleGesture:(UIGestureRecognizer *)gesture;

@property (nonatomic,retain) NSNumber *onValue;
@property (nonatomic) YapInteractiveSwitchState state;

//Tweaks
@property (nonatomic) CGFloat slip; //Slip of 0 (Default) moves item 1:1 with gesture. Slip of 1 will not move at all.
@property (nonatomic) CGFloat friction;
@property (nonatomic) CGFloat tension;

@end
