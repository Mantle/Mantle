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

NSString * const MTLModelKeyedArchiveFormat = @"MTLModelKeyedArchiveFormat";
NSString * const MTLModelJSONFormat = @"MTLModelJSONFormat";

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

// The key under which the old external representation format was encoded into
// a keyed archive.
static NSString * const MTLModelArchivedExternalRepresentationKey = @"externalRepresentation";

// Associated with an NSArray of the key paths that were encoded into the
// archive by -encodeWithCoder:.
static NSString * const MTLModelArchivedKeyPathsKey = @"MTLModelArchivedKeyPaths";

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

// Sets the value at the given key path in the given dictionary, creating
// intermediate dictionaries as necessary.
static void setValueForKeyPathAddingDictionaries (NSMutableDictionary *dict, NSString *keyPath, id value) {
	NSCParameterAssert(dict != nil);
	NSCParameterAssert(keyPath);
	NSCParameterAssert(value != nil);

	NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

	if (value != nil && ![value isEqual:NSNull.null]) {
		// Set up intermediate key paths if the value we'd be setting isn't
		// nil.
		id obj = dict;
		for (NSString *component in keyPathComponents) {
			if ([obj valueForKey:component] == nil) {
				// Insert an empty mutable dictionary at this spot so that we
				// can set the whole key path afterward.
				[obj setValue:[NSMutableDictionary dictionary] forKey:component];
			}

			obj = [obj valueForKey:component];
		}
	}

	[dict setValue:value forKeyPath:keyPath];
}

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

+ (instancetype)modelWithExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat {
	return [[self alloc] initWithExternalRepresentation:externalRepresentation inFormat:externalRepresentationFormat];
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

			// Fail fast in Debug builds.
			#if DEBUG
			@throw ex;
			#endif
		}
	}

	return self;
}

- (instancetype)initWithExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat {
	NSParameterAssert(externalRepresentationFormat != nil);

	if (externalRepresentation == nil) return nil;

	NSDictionary *externalKeyPathsByPropertyKey = [self.class keyPathsByPropertyKeyForExternalRepresentationFormat:externalRepresentationFormat];
	NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:[externalRepresentation count]];

	for (NSString *propertyKey in self.class.propertyKeys) {
		NSString *externalKeyPath = externalKeyPathsByPropertyKey[propertyKey] ?: propertyKey;

		id value = [externalRepresentation valueForKeyPath:externalKeyPath];
		if (value == nil) continue;

		NSValueTransformer *transformer = [self.class transformerForPropertyKey:propertyKey externalRepresentationFormat:externalRepresentationFormat];
		@try {
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				value = [transformer transformedValue:value] ?: NSNull.null;
			}

			properties[propertyKey] = value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception transforming external key path \"%@\" in format %@ from %@: %@", externalKeyPath, externalRepresentationFormat, externalRepresentation, ex);

			// Fail fast in Debug builds.
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

- (NSDictionary *)dictionaryValue {
	return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
}

#pragma mark External Representations

+ (NSDictionary *)keyPathsByPropertyKeyForExternalRepresentationFormat:(NSString *)externalRepresentationFormat {
	NSParameterAssert(externalRepresentationFormat != nil);

	if ([externalRepresentationFormat isEqual:MTLModelJSONFormat]) {
		// Use the old API for JSON.
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated"
		return self.externalRepresentationKeyPathsByPropertyKey;
		#pragma clang diagnostic pop
	} else {
		return @{};
	}
}

+ (NSValueTransformer *)transformerForPropertyKey:(NSString *)key externalRepresentationFormat:(NSString *)externalRepresentationFormat {
	NSParameterAssert(key != nil);
	NSParameterAssert(externalRepresentationFormat != nil);

	SEL selector = NSSelectorFromString([key stringByAppendingString:@"TransformerForExternalRepresentationFormat:"]);
	if (![self respondsToSelector:selector]) {
		if (![externalRepresentationFormat isEqual:MTLModelJSONFormat]) return nil;

		// Use the old API for JSON.
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated"
		return [self transformerForKey:key];
		#pragma clang diagnostic pop
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation setArgument:&externalRepresentationFormat atIndex:2];
	[invocation invoke];

	__unsafe_unretained id transformer = nil;
	[invocation getReturnValue:&transformer];

	return transformer;
}

+ (NSDictionary *)encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:(NSString *)externalRepresentationFormat {
	NSSet *propertyKeys = self.propertyKeys;
	NSMutableDictionary *behaviors = [NSMutableDictionary dictionaryWithCapacity:propertyKeys.count];

	for (NSString *key in propertyKeys) {
		objc_property_t property = class_getProperty(self, key.UTF8String);

		ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};

		if (attributes->weak) {
			behaviors[key] = @(MTLModelEncodingBehaviorConditional);
		} else {
			behaviors[key] = @(MTLModelEncodingBehaviorUnconditional);
		}
	}

	return behaviors;
}

- (id)externalRepresentationInFormat:(NSString *)externalRepresentationFormat {
	NSParameterAssert(externalRepresentationFormat != nil);

	NSDictionary *dictionary = self.dictionaryValue;
	NSDictionary *externalKeyPathsByPropertyKey = [self.class keyPathsByPropertyKeyForExternalRepresentationFormat:externalRepresentationFormat];
	NSDictionary *encodingBehaviors = [self.class encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:externalRepresentationFormat];

	NSMutableDictionary *mappedDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

	[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		// Also handles the case of propertyKey not being in the behaviors
		// dictionary.
		if ([encodingBehaviors[propertyKey] unsignedIntegerValue] == MTLModelEncodingBehaviorNone) {
			return;
		}

		NSValueTransformer *transformer = [self.class transformerForPropertyKey:propertyKey externalRepresentationFormat:externalRepresentationFormat];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionary we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;
			value = [transformer reverseTransformedValue:value] ?: NSNull.null;
		}

		NSString *externalKeyPath = externalKeyPathsByPropertyKey[propertyKey] ?: propertyKey;
		setValueForKeyPathAddingDictionaries(mappedDictionary, externalKeyPath, value);
	}];

	return [mappedDictionary copy];
}

#pragma mark Versioning and Migration

+ (NSUInteger)modelVersion {
	return 0;
}

+ (NSDictionary *)migrateExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(externalRepresentation != nil);
	NSParameterAssert(externalRepresentationFormat != nil);
	NSParameterAssert(fromVersion < self.modelVersion);

	if ([externalRepresentationFormat isEqual:MTLModelJSONFormat]) {
		// Use the old API for JSON.
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated"
		return [self migrateExternalRepresentation:externalRepresentation fromVersion:fromVersion];
		#pragma clang diagnostic pop
	} else {
		return externalRepresentation;
	}
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
	NSArray *archivedKeyPaths = [coder decodeObjectForKey:MTLModelArchivedKeyPathsKey];
	id externalRepresentation;

	if (archivedKeyPaths != nil) {
		// New format
		externalRepresentation = [NSMutableDictionary dictionaryWithCapacity:archivedKeyPaths.count];
		for (NSString *keyPath in archivedKeyPaths) {
			id value = [coder decodeObjectForKey:keyPath];
			if (value == nil) continue;

			setValueForKeyPathAddingDictionaries(externalRepresentation, keyPath, value);
		}
	} else {
		// Old format
		externalRepresentation = [coder decodeObjectForKey:MTLModelArchivedExternalRepresentationKey];
	}

	if (externalRepresentation == nil) return nil;

	NSNumber *version = [coder decodeObjectForKey:MTLModelVersionKey];
	if (version == nil) {
		NSLog(@"Warning: decoding an external representation without a version: %@", externalRepresentation);
	} else if (version.unsignedIntegerValue > self.class.modelVersion) {
		// Don't try to decode newer versions.
		return nil;
	} else if (version.unsignedIntegerValue < self.class.modelVersion) {
		externalRepresentation = [self.class migrateExternalRepresentation:externalRepresentation inFormat:MTLModelKeyedArchiveFormat fromVersion:version.unsignedIntegerValue];
		if (externalRepresentation == nil) return nil;
	}

	if ([self methodForSelector:@selector(initWithExternalRepresentation:)] != [MTLModel instanceMethodForSelector:@selector(initWithExternalRepresentation:)]) {
		// This class has overridden -initWithExternalRepresentation:, which
		// means it must be old code that has yet to be upgraded. Continue to
		// invoke that initializer for backwards compatibility.
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated"
		return [self initWithExternalRepresentation:externalRepresentation];
		#pragma clang diagnostic pop
	} else {
		return [self initWithExternalRepresentation:externalRepresentation inFormat:MTLModelKeyedArchiveFormat];
	}
}

- (void)encodeWithCoder:(NSCoder *)coder {
	NSSet *propertyKeys = self.class.propertyKeys;
	NSDictionary *encodingBehaviors = [self.class encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:MTLModelKeyedArchiveFormat];
	NSDictionary *externalKeyPathsByPropertyKey = [self.class keyPathsByPropertyKeyForExternalRepresentationFormat:MTLModelKeyedArchiveFormat];
	NSDictionary *externalRepresentation = [self externalRepresentationInFormat:MTLModelKeyedArchiveFormat];

	NSMutableArray *archivedKeyPaths = [NSMutableArray arrayWithCapacity:externalRepresentation.count];
	for (NSString *propertyKey in propertyKeys) {
		NSString *externalKeyPath = externalKeyPathsByPropertyKey[propertyKey] ?: propertyKey;

		id value = [externalRepresentation valueForKeyPath:externalKeyPath];
		if (value == nil) continue;

		MTLModelEncodingBehavior behavior = [encodingBehaviors[propertyKey] unsignedIntegerValue];
		NSAssert(behavior != MTLModelEncodingBehaviorNone, @"Property \"%@\" should not have MTLModelEncodingBehaviorNone while in external representation: %@", propertyKey, externalRepresentation);

		if (behavior == MTLModelEncodingBehaviorConditional) {
			[coder encodeConditionalObject:value forKey:externalKeyPath];
		} else {
			[coder encodeObject:value forKey:externalKeyPath];
		}

		[archivedKeyPaths addObject:externalKeyPath];
	}

	[coder encodeObject:archivedKeyPaths forKey:MTLModelArchivedKeyPathsKey];
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

#pragma mark Deprecated methods

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (NSDictionary *)externalRepresentation {
	return [self externalRepresentationInFormat:MTLModelJSONFormat];
}

+ (instancetype)modelWithExternalRepresentation:(NSDictionary *)externalRepresentation {
	return [self modelWithExternalRepresentation:externalRepresentation inFormat:MTLModelJSONFormat];
}

- (instancetype)initWithExternalRepresentation:(NSDictionary *)externalRepresentation {
	return [self initWithExternalRepresentation:externalRepresentation inFormat:MTLModelJSONFormat];
}

+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(fromVersion < self.modelVersion);

	return dictionary;
}

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

#pragma clang diagnostic pop

@end
