//
//  YapInteractivePerformer.h
//  Yap Interactive Switch
//
//  Created by Ollie Wagner on 12/11/13.
//  Copyright (c) 2013 Yap Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YapInteractivePerformance : NSObject

- (id)initWithActors:(NSArray *)actors;
@property (readonly) NSArray *actors;

@property (nonatomic, retain) NSDictionary *fromProperties;
@property (nonatomic, retain) NSDictionary *toProperties;

@end
