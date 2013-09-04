//
//  MTLCoreDataObjects.m
//  Mantle
//
//  Created by Robert Böhnke on 9/4/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataObjects.h"

@implementation MTLChild

@dynamic childID;
@dynamic parent1;
@dynamic parent2;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);

	return [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:moc];
}

@end

@implementation MTLParent

@dynamic date;
@dynamic number;
@dynamic string;
@dynamic unorderedChildren;
@dynamic orderedChildren;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);

	return [NSEntityDescription insertNewObjectForEntityForName:@"Parent" inManagedObjectContext:moc];
}

// Working around http://openradar.appspot.com/10114310
- (void)addOrderedChildrenObject:(MTLChild*)child {
	NSMutableOrderedSet *mutableCopy = [self.orderedChildren mutableCopy];

	[mutableCopy addObject:child];

	self.orderedChildren = [mutableCopy copy];
}

- (void)removeOrderedChildrenObject:(MTLChild*)child {
	NSMutableOrderedSet *mutableCopy = [self.orderedChildren mutableCopy];

	[mutableCopy removeObject:child];

	self.orderedChildren = [mutableCopy copy];
}

@end
