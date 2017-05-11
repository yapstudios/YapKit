//
//  YapSoundFX.m
//
//  Created by Ollie Wagner on 4/11/14.
//  Copyright (c) 2014 Yap Studios LLC. All rights reserved.
//

#import "YapSoundFX.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation YapSoundFX {
    NSMutableArray *_activePlayers;
}

static YapSoundFX *_sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [YapSoundFX new];
    });
    
	return _sharedInstance;
}

- (id)init
{
	if (self = [super init]) {
		_activePlayers = [NSMutableArray array];
	}
	return self;
}

- (CGFloat)currentVolume
{
	AVAudioSession *session = [AVAudioSession sharedInstance];
	CGFloat volume = session.outputVolume;
	return volume;
}

- (void)playSoundWithPath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle relativeVolume:(CGFloat)volume
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		NSString *pathAndType = [bundle pathForResource:path ofType:type];
		NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:pathAndType];
		NSData *data = [NSData dataWithContentsOfURL:fileURL];
		dispatch_async(dispatch_get_main_queue(), ^{
			// Per Apple's documentation...recreate the audio player upon playback of each file. Details here: https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/MultimediaPG/UsingAudio/UsingAudio.html#//apple_ref/doc/uid/TP40009767-CH2-SW2
			AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:NULL];
			// Adjust the volume in relation to the device volume
			player.volume = fminf(volume / pow([self currentVolume], 3.0), 1.0);
			player.delegate = self;
			[player play];
			[_activePlayers addObject:player];
		});
	});
}

- (void)playSoundWithPath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle
{
	[self playSoundWithPath:path ofType:type inBundle:bundle relativeVolume:1.0];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
{
	[_activePlayers removeObject:player];
}

@end
