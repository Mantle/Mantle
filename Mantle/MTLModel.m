//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLModel.h"
#import "EXTKeyPathCoding.h"
#import "EXTScope.h"
#import "NSDictionary+MTLHigherOrderAdditions.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

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

- (instancetype)init {
	return [self initWithPropertyKeysAndValues:nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	NSDictionary *keysByProperty = self.class.dictionaryKeysByPropertyKey;
	NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

	for (NSString *key in dictionary) {
		NSString *propertyKey = [keysByProperty mav_keyOfEntryPassingTest:^(NSString *propertyKey, NSString *dictionaryKey, BOOL *stop) {
			return [dictionaryKey isEqualToString:key];
		}];

		propertyKey = propertyKey ?: key;

		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];
		
		if ([value isEqual:NSNull.null]) value = nil;

		@try {
			NSValueTransformer *transformer = [self.class propertyTransformerForKey:propertyKey];
			if (transformer != nil) value = [transformer transformedValue:value];

			if (![self validateValue:&value forKey:propertyKey error:NULL]) return nil;

			value = value ?: NSNull.null;
			[properties setObject:value forKey:propertyKey];
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception setting value for key \"%@\" (dictionary key \"%@\") from dictionary %@", propertyKey, key, dictionary);

			#if DEBUG
			@throw ex;
			#endif
		}
	}

	return [self initWithPropertyKeysAndValues:properties];
}

- (instancetype)initWithPropertyKeysAndValues:(NSDictionary *)propertyKeysAndValues {
	self = [super init];
	if (self == nil) return nil;

	NSDictionary *defaultValues = self.class.defaultValuesForKeys;
	if (defaultValues != nil) [self setValuesForKeysWithDictionary:defaultValues];
	if (propertyKeysAndValues != nil) [self setValuesForKeysWithDictionary:propertyKeysAndValues];

	return self;
}

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
	Class cls = self;
	BOOL stop = NO;

	while (!stop && ![cls isEqual:MTLModel.class]) {
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);
		if (properties == NULL) continue;

		@onExit {
			free(properties);
		};

		for (unsigned i = 0; i < count; i++) {
			block(properties[i], &stop);
			if (stop) break;
		}

		cls = cls.superclass;
	}
}

+ (NSSet *)propertyKeys {
	NSMutableSet *keys = [NSMutableSet set];

	[self.class enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
		NSString *key = @(property_getName(property));
		[keys addObject:key];
	}];

	return keys;
}

#pragma mark Dictionary Representation

+ (NSDictionary *)defaultValuesForKeys {
	return @{};
}

+ (NSDictionary *)dictionaryKeysByPropertyKey {
	return @{};
}

+ (NSValueTransformer *)propertyTransformerForKey:(NSString *)key {
	NSParameterAssert(key.length > 0);

	NSString *methodName = [NSString stringWithFormat:@"propertyTransformerFor%@%@", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
	SEL selector = NSSelectorFromString(methodName);
	if (![self respondsToSelector:selector]) {
		return nil;
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation invoke];

	__unsafe_unretained id transformer = nil;
	[invocation getReturnValue:&transformer];

	return transformer;
}

- (NSDictionary *)dictionaryRepresentation {
	NSSet *keys = self.class.propertyKeys;
	NSDictionary *dictionary = [self dictionaryWithValuesForKeys:keys.allObjects];

	NSDictionary *mapping = self.class.dictionaryKeysByPropertyKey;
	NSMutableDictionary *mappedDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

	[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
		NSValueTransformer *transformer = [self.class propertyTransformerForKey:key];
		if ([transformer.class allowsReverseTransformation]) value = [transformer reverseTransformedValue:value];

		NSString *mappedKey = [mapping objectForKey:key] ?: key;
		[mappedDictionary setObject:value forKey:mappedKey];
	}];

	return [mappedDictionary copy];
}

#pragma mark Versioning and Migration

+ (NSUInteger)modelVersion {
	return 0;
}

+ (NSDictionary *)migrateDictionaryRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(fromVersion < self.modelVersion);

	return dictionary;
}

#pragma mark Merging

- (id)valueForKey:(NSString *)key mergedFromModel:(MTLModel *)model {
	NSParameterAssert(key != nil);

	SEL selector = NSSelectorFromString([key stringByAppendingString:@"MergedFromModel:"]);
	if (![self respondsToSelector:selector]) {
		return [(model ?: self) valueForKey:key];
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;

	[invocation setArgument:&model atIndex:2];
	[invocation invoke];

	__unsafe_unretained id mergedValue = nil;
	[invocation getReturnValue:&mergedValue];

	return mergedValue;
}

- (instancetype)modelByMergingFromModel:(MTLModel *)model {
	NSParameterAssert(model == nil || [model isKindOfClass:self.class]);

	NSSet *keys = self.class.propertyKeys;
	NSDictionary *dictionaryKeysByPropertyKey = self.class.dictionaryKeysByPropertyKey;

	NSMutableDictionary *mergedValues = [NSMutableDictionary dictionaryWithCapacity:keys.count];

	for (NSString *key in keys) {
		id mergedValue = [self valueForKey:key mergedFromModel:model];
		if (mergedValue == nil) mergedValue = NSNull.null;

		NSString *mappedKey = [dictionaryKeysByPropertyKey objectForKey:key] ?: key;
		[mergedValues setObject:mergedValue forKey:mappedKey];
	}

	return [self.class modelWithDictionary:mergedValues];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	NSDictionary *dictionary = [coder decodeObjectForKey:@keypath(self.dictionaryRepresentation)];
	if (dictionary == nil) return nil;

	NSNumber *version = [coder decodeObjectForKey:MTLModelVersionKey];
	if (version == nil) {
		NSLog(@"Warning: decoding a dictionary representation without a version: %@", dictionary);
	} else if (version.unsignedIntegerValue > self.class.modelVersion) {
		// Don't try to decode newer versions.
		return nil;
	} else if (version.unsignedIntegerValue < self.class.modelVersion) {
		dictionary = [self.class migrateDictionaryRepresentation:dictionary fromVersion:version.unsignedIntegerValue];
		if (dictionary == nil) return nil;
	}

	return [self initWithDictionary:dictionary];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.dictionaryRepresentation forKey:@keypath(self.dictionaryRepresentation)];
	[coder encodeObject:@(self.class.modelVersion) forKey:MTLModelVersionKey];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.dictionaryRepresentation];
}

- (NSUInteger)hash {
	return self.dictionaryRepresentation.hash;
}

- (BOOL)isEqual:(MTLModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	return [self.dictionaryRepresentation isEqualToDictionary:model.dictionaryRepresentation];
}

@end
