//
//  NSArray+MTLManipulationAdditions.m
//  Mantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+MTLManipulationAdditions.h"
#import "NSArray+MTLHigherOrderAdditions.h"

@implementation NSArray (MTLManipulationAdditions)

- (id)mtl_firstObject {
	return self.count > 0 ? [self objectAtIndex:0] : nil;
}

- (instancetype)mtl_arrayByRemovingObject:(id)object {
	return [self mtl_filterUsingBlock:^ BOOL (id arrayObject) {
		return ![arrayObject isEqual:object];
	}];
}

- (instancetype)mtl_arrayByRemovingFirstObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)mtl_arrayByRemovingLastObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}

@end
