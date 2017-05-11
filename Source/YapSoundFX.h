//
//  YapSoundFX.h
//
//  Created by Ollie Wagner on 4/11/14.
//  Copyright (c) 2014 Yap Studios LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface YapSoundFX : NSObject <AVAudioPlayerDelegate>

+ (instancetype)sharedInstance;

- (void)playSoundWithPath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle relativeVolume:(CGFloat)volume;
- (void)playSoundWithPath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle;

@end
