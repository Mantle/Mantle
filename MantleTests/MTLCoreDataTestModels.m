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

+ (NSValueTransformer *)numberStringEntityAttributeTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^ id (NSNumber *num, BOOL *success, NSError **error) {
		if (![num isKindOfClass:NSNumber.class]) {
			if (error != NULL) {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected NSNumber, got %@", @""), num];

				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert number to string", @""),
					NSLocalizedFailureReasonErrorKey: failureReason,
				};

				*error = [NSError errorWithDomain:@"MTLCoreDataTestModelsDomain" code:666 userInfo:userInfo];
			}
			*success = NO;
			return nil;
		}

		return num.stringValue;
	} reverseBlock:^ id (NSString *str, BOOL *success, NSError **error) {
		if (![str isKindOfClass:NSString.class]) {
			if (error != NULL) {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected NSString, got %@", @""), str];

				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string to number", @""),
					NSLocalizedFailureReasonErrorKey: failureReason,
				};

				*error = [NSError errorWithDomain:@"MTLCoreDataTestModelsDomain" code:666 userInfo:userInfo];
			}
			*success = NO;
			return nil;
		}

		return [NSDecimalNumber decimalNumberWithString:str];
	}];
}

+ (NSValueTransformer *)URLEntityAttributeTransformer {
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
