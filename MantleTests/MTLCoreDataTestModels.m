//
//  MTLCoreDataTestModels.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-04-05.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataTestModels.h"

@implementation MTLParentTestModel

+ (NSString *)managedObjectEntityName {
	return @"Parent";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{
		@"numberString": @"number",
		@"requiredString": @"string"
	};
}

+ (NSSet *)propertyKeysForManagedObjectUniquing {
	return [NSSet setWithObject:@"numberString"];
}

+ (NSValueTransformer *)numberStringEntityAttributeTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
		return [NSDecimalNumber decimalNumberWithString:str];
	} reverseBlock:^(NSNumber *num) {
		return num.stringValue;
	}];
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"orderedChildren": MTLChildTestModel.class,
		@"unorderedChildren": MTLChildTestModel.class,
	};
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@implementation MTLParentMergingTestModel

- (void)mergeValueForKey:(NSString *)key fromManagedObject:(NSManagedObject *)managedObject {
	if ([key isEqualToString:@"requiredString"]) {
		self.requiredString = @"merged";
	}
}

@end

@implementation MTLParentIncorrectTestModel

+ (NSString *)managedObjectEntityName {
	return @"Parent";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@implementation MTLChildTestModel

+ (NSString *)managedObjectEntityName {
	return @"Child";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

+ (NSSet *)propertyKeysForManagedObjectUniquing {
	return [NSSet setWithObjects:@"childID", nil];
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"parent1": MTLParentTestModel.class,
		@"parent2": MTLParentTestModel.class,
	};
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@implementation MTLBadChildTestModel

+ (NSString *)managedObjectEntityName {
	return @"BadChild";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

+ (NSSet *)propertyKeysForManagedObjectUniquing {
	return [NSSet setWithObjects:@"childID", nil];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@implementation MTLFailureModel

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

+ (NSString *)managedObjectEntityName {
	return @"Empty";
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@implementation MTLIllegalManagedObjectMappingModel

+ (NSString *)managedObjectEntityName {
	return @"Parent";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{
		@"name": @"username"
	};
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end
