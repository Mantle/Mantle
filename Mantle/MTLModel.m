//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLModel.h"
#import "EXTKeyPathCoding.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "NSDictionary+MTLHigherOrderAdditions.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

@interface MTLModel ()

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MTLModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block;

@end

@implementation MTLModel

#pragma mark Lifecycle

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithDictionary:dictionary];
}

+ (instancetype)modelWithExternalRepresentation:(NSDictionary *)externalRepresentation {
	return [[self alloc] initWithExternalRepresentation:externalRepresentation];
}

- (instancetype)init {
	// Nothing special by default, but we have a declaration in the header.
	return [super init];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];
	if (self == nil) return nil;

	for (NSString *key in dictionary) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];
	
		if ([value isEqual:NSNull.null]) value = nil;

		@try {
			if (![self validateValue:&value forKey:key error:NULL]) return nil;

			[self setValue:value forKey:key];
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception setting key \"%@\" from %@: %@", key, dictionary, ex);

			#if DEBUG
			@throw ex;
			#endif
		}
	}

	return self;
}

- (instancetype)initWithExternalRepresentation:(NSDictionary *)externalRepresentation {
	if (externalRepresentation == nil) return nil;

	NSDictionary *externalKeyPathsByPropertyKey = self.class.externalRepresentationKeyPathsByPropertyKey;
	NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:externalRepresentation.count];

	for (NSString *propertyKey in self.class.propertyKeys) {
		NSString *externalKeyPath = externalKeyPathsByPropertyKey[propertyKey] ?: propertyKey;

		id value = [externalRepresentation valueForKeyPath:externalKeyPath];
		if (value == nil) continue;

		NSValueTransformer *transformer = [self.class transformerForKey:propertyKey];
		@try {
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				value = [transformer transformedValue:value] ?: NSNull.null;
			}

			[properties setObject:value forKey:propertyKey];
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception transforming external key path \"%@\" from %@ using transformer %@: %@", externalKeyPath, externalRepresentation, transformer, ex);

			#if DEBUG
			@throw ex;
			#endif
		}
	}

	return [self initWithDictionary:properties];
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
		ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};

		if (attributes->readonly && attributes->ivar == NULL) return;

		NSString *key = @(property_getName(property));
		[keys addObject:key];
	}];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);

	return keys;
}

#pragma mark Dictionary Representation

+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey {
	return @{};
}

+ (NSValueTransformer *)transformerForKey:(NSString *)key {
	SEL selector = NSSelectorFromString([key stringByAppendingString:@"Transformer"]);
	if (![self respondsToSelector:selector]) return nil;

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation invoke];

	__unsafe_unretained id transformer = nil;
	[invocation getReturnValue:&transformer];

	return transformer;
}

- (NSDictionary *)dictionaryValue {
	return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
}

- (NSDictionary *)externalRepresentation {
	NSDictionary *dictionary = self.dictionaryValue;

	NSDictionary *externalKeyPathsByPropertyKey = self.class.externalRepresentationKeyPathsByPropertyKey;
	NSMutableDictionary *mappedDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

	[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		NSValueTransformer *transformer = [self.class transformerForKey:propertyKey];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionary we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;
			value = [transformer reverseTransformedValue:value] ?: NSNull.null;
		}

		NSString *externalKeyPath = externalKeyPathsByPropertyKey[propertyKey] ?: propertyKey;
		NSArray *keyPathComponents = [externalKeyPath componentsSeparatedByString:@"."];

		if (![value isEqual:NSNull.null]) {
			// Set up intermediate key paths if the value we'd be setting isn't
			// nil.
			id obj = mappedDictionary;
			for (NSString *component in keyPathComponents) {
				if ([obj valueForKey:component] == nil) {
					// Insert an empty mutable dictionary at this spot so that we
					// can set the whole key path afterward.
					[obj setValue:[NSMutableDictionary dictionary] forKey:component];
				}

				obj = [obj valueForKey:component];
			}
		}

		[mappedDictionary setValue:value forKeyPath:externalKeyPath];
	}];

	return [mappedDictionary copy];
}

#pragma mark Versioning and Migration

+ (NSUInteger)modelVersion {
	return 0;
}

+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(fromVersion < self.modelVersion);

	return dictionary;
}

#pragma mark Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model {
	NSParameterAssert(key != nil);

	NSString *methodName = [NSString stringWithFormat:@"merge%@%@FromModel:", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
	SEL selector = NSSelectorFromString(methodName);
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

- (void)mergeValuesForKeysFromModel:(MTLModel *)model {
	for (NSString *key in self.class.propertyKeys) {
		[self mergeValueForKey:key fromModel:model];
	}
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	NSDictionary *externalRepresentation = [coder decodeObjectForKey:@keypath(self.externalRepresentation)];
	if (externalRepresentation == nil) return nil;

	NSNumber *version = [coder decodeObjectForKey:MTLModelVersionKey];
	if (version == nil) {
		NSLog(@"Warning: decoding an external representation without a version: %@", externalRepresentation);
	} else if (version.unsignedIntegerValue > self.class.modelVersion) {
		// Don't try to decode newer versions.
		return nil;
	} else if (version.unsignedIntegerValue < self.class.modelVersion) {
		externalRepresentation = [self.class migrateExternalRepresentation:externalRepresentation fromVersion:version.unsignedIntegerValue];
		if (externalRepresentation == nil) return nil;
	}

	return [self initWithExternalRepresentation:externalRepresentation];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.externalRepresentation forKey:@keypath(self.externalRepresentation)];
	[coder encodeObject:@(self.class.modelVersion) forKey:MTLModelVersionKey];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.dictionaryValue];
}

- (NSUInteger)hash {
	NSUInteger value = 0;

	for (NSString *key in self.class.propertyKeys) {
		value ^= [[self valueForKey:key] hash];
	}

	return value;
}

- (BOOL)isEqual:(MTLModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	for (NSString *key in self.class.propertyKeys) {
		id selfValue = [self valueForKey:key];
		id modelValue = [model valueForKey:key];

		BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
		if (!valuesEqual) return NO;
	}

	return YES;
}

@end
