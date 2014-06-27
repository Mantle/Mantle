//
//  MTLTestJSONAdapter.m
//  Mantle
//
//  Created by Robert Böhnke on 03/04/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLTestJSONAdapter.h"

@implementation MTLTestJSONAdapter

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MTLJSONSerializing>)model {
	NSMutableSet *copy = [propertyKeys mutableCopy];

	[copy minusSet:self.ignoredPropertyKeys];

	return copy;
}

@end
