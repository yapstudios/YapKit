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
- (NSString *)transformKeyPath;
- (NSNumber *)valueFromGesture:(UIGestureRecognizer *)gesture;
- (NSNumber *)identityValue;

//never call this directly - this is the selector that subclasses should attach to their gesture
- (void)handleGesture:(UIGestureRecognizer *)gesture;

@property (nonatomic,retain) NSNumber *toValue;
@property (nonatomic) YapInteractiveSwitchState state;

@end
