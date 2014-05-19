//
//  MTLManagedObjectModel.m
//  Mantle
//
//  Created by Christian Bianciotto on 14/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLManagedObjectModel.h"

@interface MTLManagedObjectModel ()

@end

@implementation MTLManagedObjectModel

#pragma mark Lifecycle

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	NSAssert(NO, @"%@ should not be initialized using -modelWithDictionary:error:, use CoreData method.", self.class);
	return nil;
}

- (instancetype)init {
	NSAssert(NO, @"%@ should not be initialized using -init, use CoreData method.", self.class);
	return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	NSAssert(NO, @"%@ should not be initialized using -initWithDictionary:error, use CoreData method.", self.class);
	return nil;
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

- (void)mergeValuesForKeysFromModel:(id<MTLModelProtocol>)model {
	[MTLBaseModel mergeValuesForKeysFromModel:model inModel:self];
}

#pragma mark Validation

- (BOOL)validate:(NSError **)error {
	return [MTLBaseModel validateModel:self error:error];
}

#pragma mark NSObject

- (NSString *)description {
	return [MTLBaseModel descriptionFromModel:self];
}

//- (NSUInteger)hash {
//	NSUInteger value = 0;
//	
//	for (NSString *key in self.class.propertyKeys) {
//		value ^= [[self valueForKey:key] hash];
//	}
//	
//	return value;
//}
//
//- (BOOL)isEqual:(MTLManagedObjectModel *)model {
//	if (self == model) return YES;
//	if (![model isMemberOfClass:self.class]) return NO;
//	
//	for (NSString *key in self.class.propertyKeys) {
//		id selfValue = [self valueForKey:key];
//		id modelValue = [model valueForKey:key];
//		
//		BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
//		if (!valuesEqual) return NO;
//	}
//	
//	return YES;
//}

@end
