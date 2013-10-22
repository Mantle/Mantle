//
//  MTLDeprecatedCoreDataTestModel.m
//  Mantle
//
//  Created by Robert Böhnke on 10/21/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataTestModels.h"

#import "MTLDeprecatedCoreDataTestModel.h"

@implementation MTLDeprecatedParentTestModel

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

+ (NSValueTransformer *)numberStringEntityAttributeTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
		return [NSDecimalNumber decimalNumberWithString:str];
	} reverseBlock:^(NSNumber *num, BOOL *success, NSError **error) {
		return num.stringValue;
	}];
}

+ (NSValueTransformer *)URLEntityAttributeTransformer {
	return [[NSValueTransformer valueTransformerForName:MTLURLValueTransformerName] mtl_invertedTransformer];
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"orderedChildren": MTLChildTestModel.class,
		@"unorderedChildren": MTLChildTestModel.class,
	};
}

@end