//
//  MTLBaseModel.m
//  Mantle
//
//  Created by Christian Bianciotto on 14/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"
#import "MTLBaseModel.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLReflection.h"

// This coupling is needed for backwards compatibility in MTLModel's deprecated
// methods.
#import "MTLJSONAdapter.h"
#import "MTLModel+NSCoding.h"

// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated. This value
//               must not be nil.
// key         - The name of one of `obj`s properties. This value must not be
//               nil.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
	// Mark this as being autoreleased, because validateValue may return
	// a new object to be stored in this variable (and we don't want ARC to
	// double-free or leak the old or new values).
	__autoreleasing id validatedValue = value;

	@try {
		if (![obj validateValue:&validatedValue forKey:key error:error]) return NO;

		if (forceUpdate || value != validatedValue) {
			[obj setValue:validatedValue forKey:key];
		}

		return YES;
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);

		// Fail fast in Debug builds.
		#if DEBUG
		@throw ex;
		#else
		if (error != NULL) {
			*error = [NSError mtl_modelErrorWithException:ex];
		}

		return NO;
		#endif
	}
}

@interface MTLBaseModel ()

@end

@implementation MTLBaseModel

#pragma mark Reflection

+ (BOOL)updateModel:(id<MTLModelProtocol>)model withDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	for (NSString *key in dictionary) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];
		
		if ([value isEqual:NSNull.null]) value = nil;
		
		if(!MTLValidateAndSetValue(model, key, value, YES, error)) return NO;
	}
	
	return YES;
}

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MTLModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)enumeratePropertiesFromModelClass:(Class<MTLModelProtocol>)modelClass usingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
	Class cls = modelClass;
	BOOL stop = NO;

	while (!stop && [cls.superclass conformsToProtocol:@protocol(MTLModelProtocol)]) {
	//while (!stop && ![cls isEqual:MTLModel.class]) {
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);

		cls = cls.superclass;
		if (properties == NULL) continue;

		@onExit {
			free(properties);
		};

		for (unsigned i = 0; i < count; i++) {
			block(properties[i], &stop);
			if (stop) break;
		}
	}
}

+ (NSSet *)propertyKeysFromModelClass:(Class<MTLModelProtocol>)modelClass {
	NSSet *cachedKeys = objc_getAssociatedObject(modelClass, MTLModelCachedPropertyKeysKey);
	if (cachedKeys != nil) return cachedKeys;

	NSMutableSet *keys = [NSMutableSet set];

	[self enumeratePropertiesFromModelClass:modelClass usingBlock:^(objc_property_t property, BOOL *stop) {
		mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};

		if (attributes->readonly && attributes->ivar == NULL) return;

		NSString *key = @(property_getName(property));
		[keys addObject:key];
	}];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(modelClass, MTLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);

	return keys;
}

+ (NSDictionary *)dictionaryValueFromModel:(NSObject<MTLModelProtocol> *)model {
	return [model dictionaryWithValuesForKeys:[self.class propertyKeysFromModelClass:model.class].allObjects];
}

#pragma mark Merging

+ (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModelProtocol> *)sourceModel inModel:(NSObject<MTLModelProtocol> *)destinationModel {
	NSParameterAssert(key != nil);

	SEL selector = MTLSelectorWithCapitalizedKeyPattern("merge", key, "FromModel:");
	if (![destinationModel respondsToSelector:selector]) {
		if (sourceModel != nil && destinationModel != nil) {
			[destinationModel setValue:[sourceModel valueForKey:key] forKey:key];
		}

		return;
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[destinationModel methodSignatureForSelector:selector]];
	invocation.target = destinationModel;
	invocation.selector = selector;

	[invocation setArgument:&sourceModel atIndex:2];
	[invocation invoke];
}

+ (void)mergeValuesForKeysFromModel:(NSObject<MTLModelProtocol> *)sourceModel inModel:(NSObject<MTLModelProtocol> *)destinationModel {
	NSSet *propertyKeys = [self.class propertyKeysFromModelClass:sourceModel.class];
	for (NSString *key in [self.class propertyKeysFromModelClass:destinationModel.class]) {
		if (![propertyKeys containsObject:key]) continue;

		[self.class mergeValueForKey:key fromModel:sourceModel inModel:destinationModel];
	}
}

#pragma mark Validation

+ (BOOL)validateModel:(NSObject<MTLModelProtocol> *)model error:(NSError **)error {
	for (NSString *key in [self.class propertyKeysFromModelClass:model.class]) {
		id value = [model valueForKey:key];

		BOOL success = MTLValidateAndSetValue(model, key, value, NO, error);
		if (!success) return NO;
	}

	return YES;
}

#pragma mark NSObject

+ (NSString *)descriptionFromModel:(NSObject<MTLModelProtocol> *)model {
	return [NSString stringWithFormat:@"<%@: %p> %@", model.class, model, model.dictionaryValue];
}

@end
