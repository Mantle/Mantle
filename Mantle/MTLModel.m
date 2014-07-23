//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"
#import "MTLModel.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLReflection.h"
#import "MTLValidateAndSetValue.h"
#import <objc/runtime.h>

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all transitory
// property keys.
static void *MTLModelCachedTransitoryPropertyKeysKey = &MTLModelCachedTransitoryPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all permanent
// property keys.
static void *MTLModelCachedPermanentPropertyKeysKey = &MTLModelCachedPermanentPropertyKeysKey;

@interface MTLModel ()

// Inspects all properties of returned by +propertyKeys using
// +storageBehaviorForPropertyWithKey and caches the results.
+ (void)generateAndCacheStorageBehaviors;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStorageTransitory.
+ (NSSet *)transitoryPropertyKeys;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStoragePermanent.
+ (NSSet *)permanentPropertyKeys;

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MTLModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block;

@end

@implementation MTLModel

#pragma mark Lifecycle

+ (void)generateAndCacheStorageBehaviors {
	NSMutableSet *transitoryKeys = [NSMutableSet set];
	NSMutableSet *permanentKeys = [NSMutableSet set];

	for (NSString *propertyKey in self.propertyKeys) {
		switch ([self storageBehaviorForPropertyWithKey:propertyKey]) {
			case MTLPropertyStorageNone:
				break;

			case MTLPropertyStorageTransitory:
				[transitoryKeys addObject:propertyKey];
				break;

			case MTLPropertyStoragePermanent:
				[permanentKeys addObject:propertyKey];
				break;
		}
	}

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey, transitoryKeys, OBJC_ASSOCIATION_COPY);
	objc_setAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey, permanentKeys, OBJC_ASSOCIATION_COPY);
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	return [[self alloc] initWithDictionary:dictionary error:error];
}

- (instancetype)init {
	// Nothing special by default, but we have a declaration in the header.
	return [super init];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	self = [self init];
	if (self == nil) return nil;

	for (NSString *key in dictionary) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];

		if ([value isEqual:NSNull.null]) value = nil;

		BOOL success = MTLValidateAndSetValue(self, key, value, YES, error);
		if (!success) return nil;
	}

	return self;
}

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
	Class cls = self;
	BOOL stop = NO;

	while (!stop && ![cls isEqual:MTLModel.class]) {
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

+ (NSSet *)propertyKeys {
	NSSet *cachedKeys = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysKey);
	if (cachedKeys != nil) return cachedKeys;

	NSMutableSet *keys = [NSMutableSet set];

	[self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
		NSString *key = @(property_getName(property));

		if ([self storageBehaviorForPropertyWithKey:key] != MTLPropertyStorageNone) {
			 [keys addObject:key];
		}
	}];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);

	return keys;
}

+ (NSSet *)transitoryPropertyKeys {
	NSSet *transitoryPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey);

	if (transitoryPropertyKeys == nil) {
		[self generateAndCacheStorageBehaviors];
		transitoryPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey);
	}

	return transitoryPropertyKeys;
}

+ (NSSet *)permanentPropertyKeys {
	NSSet *permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);

	if (permanentPropertyKeys == nil) {
		[self generateAndCacheStorageBehaviors];
		permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);
	}

	return permanentPropertyKeys;
}

- (NSDictionary *)dictionaryValue {
	NSSet *keys = [self.class.transitoryPropertyKeys setByAddingObjectsFromSet:self.class.permanentPropertyKeys];

	return [self dictionaryWithValuesForKeys:keys.allObjects];
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	objc_property_t property = class_getProperty(self.class, propertyKey.UTF8String);

	if (property == NULL) return MTLPropertyStorageNone;

	mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	@onExit {
		free(attributes);
	};

	if (attributes->readonly && attributes->ivar == NULL) {
		return MTLPropertyStorageNone;
	} else {
		return MTLPropertyStoragePermanent;
	}
}

#pragma mark Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModel> *)model {
	NSParameterAssert(key != nil);

	SEL selector = MTLSelectorWithCapitalizedKeyPattern("merge", key, "FromModel:");
	if (![self respondsToSelector:selector]) {
		if (model != nil) {
			[self setValue:[model valueForKey:key] forKey:key];
		}

		return;
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;

	[invocation setArgument:&model atIndex:2];
	[invocation invoke];
}

- (void)mergeValuesForKeysFromModel:(id<MTLModel>)model {
	NSSet *propertyKeys = model.class.propertyKeys;

	for (NSString *key in self.class.propertyKeys) {
		if (![propertyKeys containsObject:key]) continue;

		[self mergeValueForKey:key fromModel:model];
	}
}

#pragma mark Validation

- (BOOL)validate:(NSError **)error {
	for (NSString *key in self.class.propertyKeys) {
		id value = [self valueForKey:key];

		BOOL success = MTLValidateAndSetValue(self, key, value, NO, error);
		if (!success) return NO;
	}

	return YES;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue error:NULL];
}

#pragma mark NSObject

- (NSString *)description {
	NSDictionary *permanentProperties = [self dictionaryWithValuesForKeys:self.class.permanentPropertyKeys.allObjects];

	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, permanentProperties];
}

- (NSUInteger)hash {
	NSUInteger value = 0;

	for (NSString *key in self.class.permanentPropertyKeys) {
		value ^= [[self valueForKey:key] hash];
	}

	return value;
}

- (BOOL)isEqual:(MTLModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	for (NSString *key in self.class.permanentPropertyKeys) {
		id selfValue = [self valueForKey:key];
		id modelValue = [model valueForKey:key];

		BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
		if (!valuesEqual) return NO;
	}

	return YES;
}

@end
