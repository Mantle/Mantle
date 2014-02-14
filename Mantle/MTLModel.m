//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"
#import "NSError+MTLValidation.h"
#import "MTLModel.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLReflection.h"
#import <objc/runtime.h>

// This coupling is needed for backwards compatibility in MTLModel's deprecated
// methods.
#import "MTLJSONAdapter.h"
#import "MTLModel+NSCoding.h"

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

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
static BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
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

#pragma mark Validation

- (BOOL)validate:(NSError **)error {
	for (NSString *key in self.class.propertyKeys) {
		id value = [self valueForKey:key];

		BOOL success = MTLValidateAndSetValue(self, key, value, NO, error);
		if (!success) return NO;
	}

	return YES;
}

- (BOOL)validateValue:(inout __autoreleasing id *)ioValue
			   forKey:(NSString *)inKey
				error:(out NSError *__autoreleasing *)outError {
	if (![super validateValue:ioValue
					   forKey:inKey
						error:outError]) {
		return NO;
	}
	if (!(*ioValue)) {
		// No way to figure out if the value is of the same type as the property
		return YES;
	}
	
	objc_property_t property = class_getProperty([self class], [inKey UTF8String]);
	mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	@onExit {
		free(attributes);
	};
	
	Class propertyClass = attributes->objectClass;
	Class valueClass = [*ioValue class];

	// can be validated using property class
	if (propertyClass) {
		if ([valueClass isSubclassOfClass:propertyClass]) {
			return YES;
		}
		// value is not a descendant of a property class
		if (outError) {
			*outError = [NSError mtl_validationErrorForProperty:inKey
												   expectedType:NSStringFromClass(propertyClass)
												   receivedType:NSStringFromClass(valueClass)];
		}
		return NO;
	}
	
	// property is a primitive type
	const char *propertyEncoding = attributes->type;
	// first check if it's a special case when attribute is of type id
	if (!propertyEncoding) {
		return YES;
	}
	
	// validating using encoding of the property

	// BOOL
	BOOL isBooleanConst = (*ioValue == (__bridge id)kCFBooleanFalse ||
						   *ioValue == (__bridge id)kCFBooleanTrue);
	if (isBooleanConst) {
		// is property has type boolean
		if (strcmp(propertyEncoding, @encode(BOOL)) == 0) {
			return YES;
		}
		// Value is not one of two boolean constant
		if (outError) {
			*outError = [NSError mtl_validationErrorForProperty:inKey
												   expectedType:@"BOOL"
												   receivedType:[NSString stringWithFormat:@"%s", propertyEncoding]];
		}
		return NO;
	}
	
	// Numbers
	
	// NSNumber, for now, we just simplify: we let NSNumber convert the
	// underlying value to the appropriate value through KVC
	// TODO: there is no way
	if ([valueClass isSubclassOfClass:[NSNumber class]]) {
		// make sure that the attribute is a numeric primitive
		BOOL isNumericType = (
			strcmp(propertyEncoding, @encode(unsigned int)) == 0 ||
			strcmp(propertyEncoding, @encode(int)) == 0 ||
			strcmp(propertyEncoding, @encode(float)) == 0 ||
			strcmp(propertyEncoding, @encode(double)) == 0 ||
			strcmp(propertyEncoding, @encode(long)) == 0 ||
			strcmp(propertyEncoding, @encode(long long)) == 0 ||
			strcmp(propertyEncoding, @encode(unsigned long)) == 0 ||
			strcmp(propertyEncoding, @encode(unsigned long long)) == 0 ||
			strcmp(propertyEncoding, @encode(unsigned char)) == 0 ||
			strcmp(propertyEncoding, @encode(unsigned short)) == 0 ||
			strcmp(propertyEncoding, @encode(char)) == 0 ||
			strcmp(propertyEncoding, @encode(short)) == 0
		);

		if (isNumericType) {
			return YES;
		}
		if (outError) {
			*outError = [NSError mtl_validationErrorForProperty:inKey
												   expectedType:[NSString stringWithFormat:@"%s", propertyEncoding]
												   receivedType:NSStringFromClass(valueClass)];
		}
		return NO;
	}
	
	// NSValue, most likely contains structures
	if ([valueClass isSubclassOfClass:[NSValue class]]) {
		// Just compare undelying encodings
		const char *valueEncoding = [((NSValue *)*ioValue) objCType];
		BOOL isStructEncodingValid = (strcmp(valueEncoding, propertyEncoding) == 0);
		if (isStructEncodingValid) {
			return YES;
		}
		if (outError) {
			*outError = [NSError mtl_validationErrorForProperty:inKey
												   expectedType:[NSString stringWithFormat:@"%s", propertyEncoding]
												   receivedType:[NSString stringWithFormat:@"%s", valueEncoding]];
		}
		return NO;
	}
	
	// actually we shouldn't get here
	return YES;
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
