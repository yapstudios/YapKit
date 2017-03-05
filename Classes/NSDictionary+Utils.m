//
//  NSDictionary+Safety.m
//  YapKit
//
//  Created by Emory Al-Imam on 3/5/17.
//  Copyright © 2017 Yap Studios. All rights reserved.
//

#import "NSDictionary+Utils.h"

@implementation NSDictionary (Utils)

- (id)objectOrNilForKey:(id)key {
	
	id object = [self objectForKey:key];
	
	if (object == [NSNull null]) {
		return nil;
	}
	
	return object;
}

@end
