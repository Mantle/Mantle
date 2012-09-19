//
//  NSArray+MAVManipulationAdditions.m
//  Maverick
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+MAVManipulationAdditions.h"

@implementation NSArray (MAVManipulationAdditions)

- (id)mav_firstObject {
	return self.count > 0 ? [self objectAtIndex:0] : nil;
}

- (instancetype)mav_arrayByRemovingObject:(id)object {
	NSMutableArray *copied = [self mutableCopy];
	[copied removeObject:object];
	return [copied copy];
}

- (instancetype)mav_arrayWithoutFirstObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)mav_arrayWithoutLastObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}

@end
