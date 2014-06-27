//
//  NSDictionary+MTLMappingAdditions.m
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLBaseModelProtocol.h"

#import "NSDictionary+MTLMappingAdditions.h"

@implementation NSDictionary (MTLMappingAdditions)

+ (NSDictionary *)mtl_identityPropertyMapWithModel:(Class)class {
	NSCParameterAssert([class conformsToProtocol:@protocol(MTLBaseModelProtocol)]);

	NSArray *propertyKeys = [class propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

@end
