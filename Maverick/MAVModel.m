//
//  MAVModel.m
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MAVModel.h"
#import "EXTKeyPathCoding.h"
#import "EXTScope.h"
#import "NSDictionary+MAVHigherOrderAdditions.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MAVModelVersionKey = @"MAVModelVersion";

@interface MAVModel ()

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MAVModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block;

@end

@implementation MAVModel

#pragma mark Lifecycle

- (id)init {
	return [self initWithDictionary:nil];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];
	if (self == nil) return nil;

	NSDictionary *defaultValues = [self.class defaultValuesForKeys];
	if (defaultValues != nil) [self setValuesForKeysWithDictionary:defaultValues];

	NSDictionary *keysByProperty = [self.class dictionaryKeysByPropertyKey];
	for (NSString *key in dictionary) {
		NSString *propertyKey = [keysByProperty mav_keyOfEntryPassingTest:^ BOOL (NSString *propertyKey, NSString *dictionaryKey, BOOL *stop){
			return [dictionaryKey isEqualToString:key];
		}];

		propertyKey = propertyKey ?: key;

		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];
		
		if ([value isEqual:[NSNull null]]) value = nil;
		if (![self validateValue:&value forKey:propertyKey error:NULL]) return nil;

		[self setValue:value forKey:propertyKey];
	}

	return self;
}

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
	Class cls = self;
	BOOL stop = NO;

	while (!stop && ![cls isEqual:[MAVModel class]]) {
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

#pragma mark Dictionary Representation

+ (NSDictionary *)defaultValuesForKeys {
	return @{};
}

+ (NSDictionary *)dictionaryKeysByPropertyKey {
	return @{};
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableSet *keys = [NSMutableSet set];

	[self.class enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop){
		NSString *key = @(property_getName(property));
		[keys addObject:key];
	}];

	NSDictionary *dictionary = [self dictionaryWithValuesForKeys:keys.allObjects];

	NSDictionary *mapping = [self.class dictionaryKeysByPropertyKey];
	NSMutableDictionary *mappedDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

	[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop){
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

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	NSDictionary *dictionary = [coder decodeObjectForKey:@keypath(self.dictionaryRepresentation)];
	if (dictionary == nil) return nil;

	NSNumber *version = [coder decodeObjectForKey:MAVModelVersionKey];
	if (version == nil) {
		NSLog(@"Warning: decoding a dictionary representation without a version: %@", dictionary);
	} else if (version.unsignedIntegerValue > [self.class modelVersion]) {
		// Don't try to decode newer versions.
		return nil;
	} else if (version.unsignedIntegerValue < [self.class modelVersion]) {
		dictionary = [self.class migrateDictionaryRepresentation:dictionary fromVersion:version.unsignedIntegerValue];
		if (dictionary == nil) return nil;
	}

	return [self initWithDictionary:dictionary];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.dictionaryRepresentation forKey:@keypath(self.dictionaryRepresentation)];
	[coder encodeObject:@([self.class modelVersion]) forKey:MAVModelVersionKey];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.dictionaryRepresentation];
}

- (NSUInteger)hash {
	return self.dictionaryRepresentation.hash;
}

- (BOOL)isEqual:(MAVModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	return [self.dictionaryRepresentation isEqualToDictionary:model.dictionaryRepresentation];
}

@end
