//
//  NSDictionary+MTLMappingAdditions.m
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

#import "NSDictionary+MTLMappingAdditions.h"

@implementation NSDictionary (MTLMappingAdditions)

+ (NSDictionary *)mtl_identityPropertyMapWithModel:(Class)class {
	NSCParameterAssert([class isSubclassOfClass:MTLModel.class]);

	NSArray *propertyKeys = [class propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

@end
