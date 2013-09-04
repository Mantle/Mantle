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

+ (NSSet *)propertyKeysForManagedObjectUniquing
{
	return [NSSet setWithObjects:@"numberString", nil];
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

@end

@implementation MTLChildTestModel

+ (NSString *)managedObjectEntityName {
	return @"Child";
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

+ (NSSet *)propertyKeysForManagedObjectUniquing
{
	return [NSSet setWithObjects:@"childID", nil];
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"parent1": MTLParentTestModel.class,
		@"parent2": MTLParentTestModel.class,
	};
}

@end
