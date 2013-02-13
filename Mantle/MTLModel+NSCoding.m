//
//  MTLModel+NSCoding.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel+NSCoding.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

@implementation MTLModel (NSCoding)

#pragma mark Versioning

+ (NSUInteger)modelVersion {
	return 0;
}

#pragma mark Encoding Behaviors

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
	NSSet *propertyKeys = self.class.propertyKeys;
	NSMutableDictionary *behaviors = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];

	for (NSString *key in propertyKeys) {
		objc_property_t property = class_getProperty(self, key.UTF8String);
		NSAssert(property != NULL, @"Could not find property \"%@\" on %@", key, self);

		ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};

		MTLModelEncodingBehavior behavior = MTLModelEncodingBehaviorUnconditional;
		if (attributes->type[0] == '@' || attributes->objectClass != nil) {
			if (attributes->weak || attributes->memoryManagementPolicy == ext_propertyMemoryManagementPolicyAssign) {
				behavior = MTLModelEncodingBehaviorConditional;
			}
		}

		behaviors[key] = @(behavior);
	}

	return behaviors;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
  	NSParameterAssert(key != nil);
	NSParameterAssert(coder != nil);

	NSString *methodName = [NSString stringWithFormat:@"decode%@%@WithCoder:modelVersion:", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
	SEL selector = NSSelectorFromString(methodName);

	if ([self respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
		invocation.target = self;
		invocation.selector = selector;
		[invocation setArgument:&coder atIndex:2];
		[invocation setArgument:&modelVersion atIndex:3];
		[invocation invoke];

		id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}

	return [coder decodeObjectForKey:key];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	NSNumber *version = [coder decodeObjectForKey:MTLModelVersionKey];
	if (version == nil) return nil;

	// Don't try to decode newer versions.
	if (version.unsignedIntegerValue > self.class.modelVersion) return nil;

	// Handle the old archive format.
	NSDictionary *externalRepresentation = [coder decodeObjectForKey:@"externalRepresentation"];
	if (externalRepresentation != nil) {
		NSAssert([self methodForSelector:@selector(dictionaryValueFromArchivedExternalRepresentation:version:)] != [MTLModel instanceMethodForSelector:@selector(dictionaryValueFromArchivedExternalRepresentation:version:)], @"Decoded an old archive of %@ that contains an externalRepresentation, but +dictionaryValueFromArchivedExternalRepresentation:version: is not overridden to handle it", self.class);

		NSDictionary *dictionaryValue = [self.class dictionaryValueFromArchivedExternalRepresentation:externalRepresentation version:version.unsignedIntegerValue];
		if (dictionaryValue == nil) return nil;

		return [self initWithDictionary:dictionaryValue];
	}

	NSSet *propertyKeys = self.class.propertyKeys;
	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];

	for (NSString *key in propertyKeys) {
		id value = [self decodeValueForKey:key withCoder:coder modelVersion:version.unsignedIntegerValue];
		if (value == nil) continue;

		dictionaryValue[key] = value;
	}

	return [self initWithDictionary:dictionaryValue];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:@(self.class.modelVersion) forKey:MTLModelVersionKey];

	NSDictionary *encodingBehaviors = self.class.encodingBehaviorsByPropertyKey;
	[self.dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
		// Skip nil values.
		if ([value isEqual:NSNull.null]) return;

		switch ([encodingBehaviors[key] unsignedIntegerValue]) {
			// This will also match a nil behavior.
			case MTLModelEncodingBehaviorExcluded:
				break;

			case MTLModelEncodingBehaviorUnconditional:
				[coder encodeObject:value forKey:key];
				break;

			case MTLModelEncodingBehaviorConditional:
				[coder encodeConditionalObject:value forKey:key];
				break;

			default:
				NSAssert(NO, @"Unrecognized encoding behavior %@ for key \"%@\"", encodingBehaviors[key], key);
		}
	}];
}

@end

@implementation MTLModel (OldArchiveSupport)

+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion {
	return nil;
}

@end
