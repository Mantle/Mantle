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
		@"requiredString": @"string",
		@"URL": @"url"
	};
}

+ (NSSet *)propertyKeysForManagedObjectUniquing {
	return [NSSet setWithObject:@"numberString"];
}

+ (NSValueTransformer *)numberStringManagedObjectAttributeTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^(NSNumber *num, BOOL *success, NSError **error) {
		return num.stringValue;
	} reverseBlock:^(NSString *str, BOOL *success, NSError **error) {
		return [NSDecimalNumber decimalNumberWithString:str];
	}];
}

+ (NSValueTransformer *)URLManagedObjectAttributeTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
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
