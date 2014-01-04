//
//  NSObject+MTLPropertyInspection.m
//  Mantle
//
//  Created by Robert Böhnke on 31/12/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "EXTScope.h"
#import "EXTRuntimeExtensions.h"
#import "MTLJSONAdapter.h"
#import "NSObject+MTLPropertyInspection.h"

@implementation NSObject (MTLPropertyInspection)

+ (Class)mtl_classOfPropertyWithKey:(NSString *)key {
	NSParameterAssert(key != nil);

	objc_property_t property = class_getProperty(self.class, key.UTF8String);

	if (property == nil) return nil;

	mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	@onExit {
		free(attributes);
	};

	return attributes->objectClass;
}

+ (char *)mtl_objCTypeOfPropertyWithKey:(NSString *)key {
	NSParameterAssert(key != nil);

	objc_property_t property = class_getProperty(self.class, key.UTF8String);

	if (property == nil) return nil;

	mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	@onExit {
		free(attributes);
	};

	return strdup(attributes->type);
}

@end
