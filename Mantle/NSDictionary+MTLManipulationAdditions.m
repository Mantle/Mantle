//
//  NSDictionary+MTLManipulationAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSDictionary+MTLManipulationAdditions.h"
#import "NSDictionary+MTLHigherOrderAdditions.h"

@implementation NSDictionary (MTLManipulationAdditions)

- (NSDictionary *)mtl_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary {
	NSMutableDictionary *result = [self mutableCopy];
	[result addEntriesFromDictionary:dictionary];

	return [result copy];
}

- (NSDictionary *)mtl_dictionaryByRemovingEntriesWithKeys:(NSSet *)keys {
	return [self mtl_filterEntriesUsingBlock:^ BOOL (id key, id value) {
		return ![keys containsObject:key];
	}];
}

@end
