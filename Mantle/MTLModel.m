//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLModel.h"

// This coupling is needed for backwards compatibility in MTLModel's deprecated
// methods.
#import "MTLJSONAdapter.h"
#import "MTLModel+NSCoding.h"

@interface MTLModel ()



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

	if (![self updateWithDictionary:dictionary error:error]) return nil;

	return self;
}

#pragma mark Reflection

- (BOOL)updateWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	return [MTLBaseModel updateModel:self withDictionary:dictionary error:error];
}

+ (NSSet *)propertyKeys {
	return [MTLBaseModel propertyKeysFromModelClass:self.class];
}

- (NSDictionary *)dictionaryValue {
	return [MTLBaseModel dictionaryValueFromModel:self];
}

#pragma mark Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(id<MTLModelProtocol>)model {
	[MTLBaseModel mergeValueForKey:key fromModel:model inModel:self];
}

- (void)mergeValuesForKeysFromModel:(MTLModel *)model {
	[MTLBaseModel mergeValuesForKeysFromModel:model inModel:self];
}

#pragma mark Validation

- (BOOL)validate:(NSError **)error {
	return [MTLBaseModel validateModel:self error:error];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue error:NULL];
}

#pragma mark NSObject

- (NSString *)description {
	return [MTLBaseModel descriptionFromModel:self];
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
