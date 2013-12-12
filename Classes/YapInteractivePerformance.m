//
//  YapInteractivePerformer.m
//  Yap Interactive Switch
//
//  Created by Ollie Wagner on 12/11/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import "YapInteractivePerformance.h"

@implementation YapInteractivePerformance

- (id)initWithActors:(NSArray *)actors
{
	self = [super init];
	if (self) {
		_actors = actors;
	}
	return self;
}

@end
