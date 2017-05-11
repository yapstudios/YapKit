//
//  YapShadowView.h
//
//  Created by Ollie Wagner on 4/4/15.
//  Copyright (c) 2015 Yap Studios LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YapShadowView : UIView

- (instancetype)initWithImage:(UIImage *)image;

// A stretchable image
@property (nonatomic, retain) UIImage *shadowImage;

@end
