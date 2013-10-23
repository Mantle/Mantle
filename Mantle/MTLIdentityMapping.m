//
//  MTLIdentityMapping.m
//  Mantle
//
//  Created by Robert Böhnke on 10/23/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

#import "MTLIdentityMapping.h"

extern NSDictionary *MTLIdentityMappingForClass(Class class) {
	NSCParameterAssert([class isSubclassOfClass:MTLModel.class]);

	NSArray *propertyKeys = [class propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}
