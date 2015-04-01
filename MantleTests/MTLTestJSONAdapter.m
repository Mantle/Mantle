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

- (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	NSDictionary *dictionary = [super JSONDictionaryFromModel:model error:error];
	return [dictionary mtl_dictionaryByAddingEntriesFromDictionary:@{
		@"test": @YES
	}];
}

@end
