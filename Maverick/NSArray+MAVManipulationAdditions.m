//
//  NSArray+MAVManipulationAdditions.m
//  Maverick
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+MAVManipulationAdditions.h"
#import "NSArray+MAVHigherOrderAdditions.h"

@implementation NSArray (MAVManipulationAdditions)

- (id)mav_firstObject {
	return self.count > 0 ? [self objectAtIndex:0] : nil;
}

- (instancetype)mav_arrayByRemovingObject:(id)object {
	return [self mav_filterUsingBlock:^ BOOL (id arrayObject) {
		return ![arrayObject isEqual:object];
	}];
}

- (instancetype)mav_arrayByRemovingFirstObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)mav_arrayByRemovingLastObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}

@end
