//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLModel.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLReflection.h"
#import <objc/runtime.h>

// This coupling is needed for backwards compatibility in MTLModel's deprecated
// methods.
#import "MTLJSONAdapter.h"
#import "MTLModel+NSCoding.h"

// The domain for errors originating from MTLModel.
static NSString * const MTLModelErrorDomain = @"MTLModelErrorDomain";

// An exception was thrown and caught.
static const NSInteger MTLModelErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MTLModelThrownExceptionErrorKey = @"MTLModelThrownException";

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

		@try {
			if (![self validateValue:&value forKey:key error:error]) return nil;

			[self setValue:value forKey:key];
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception setting key \"%@\" from %@: %@", key, dictionary, ex);

			// Fail fast in Debug builds.
			#if DEBUG
			@throw ex;
			#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: ex.description,
					NSLocalizedFailureReasonErrorKey: ex.reason,
					MTLModelThrownExceptionErrorKey: ex
				};

				*error = [NSError errorWithDomain:MTLModelErrorDomain code:MTLModelErrorExceptionThrown userInfo:userInfo];
			}

			return nil;
			#endif
		}
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

#pragma mark Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model {
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

- (void)mergeValuesForKeysFromModel:(MTLModel *)model {
	for (NSString *key in self.class.propertyKeys) {
		[self mergeValueForKey:key fromModel:model];
	}
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue error:NULL];
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
