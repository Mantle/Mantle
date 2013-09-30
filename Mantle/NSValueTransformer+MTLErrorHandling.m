//
//  NSValueTransformer+MTLErrorHandling.m
//  Mantle
//
//  Created by Robert Böhnke on 9/30/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLErrorHandling.h"

NSString * const MTLValueTransformerErrorDomain = @"MTLNSValueTransformerErrorDomain";

const NSInteger MTLValueTransformerErrorTransformationFailed = 1;

@implementation NSValueTransformer (MTLErrorHandling)

- (id)mtl_transformedValue:(id)value error:(NSError **)error {
	id transformedValue = [self transformedValue:value];

	if (transformedValue == nil && error != NULL) {
		NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Failed to transform %@", @""), value];

		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform value", @""),
			NSLocalizedFailureReasonErrorKey: failureReason
		};

		*error = [NSError errorWithDomain:MTLValueTransformerErrorDomain code:MTLValueTransformerErrorTransformationFailed userInfo:userInfo];
	}

	return transformedValue;
}

- (id)mtl_reverseTransformedValue:(id)value error:(NSError **)error {
	id reverseTransformedValue = [self reverseTransformedValue:value];

	if (reverseTransformedValue == nil && error != NULL) {
		NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Failed to reverse transform %@", @""), value];

		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"Could not reverse transform value", @""),
			NSLocalizedFailureReasonErrorKey: failureReason
		};

		*error = [NSError errorWithDomain:MTLValueTransformerErrorDomain code:MTLValueTransformerErrorTransformationFailed userInfo:userInfo];
	}
	
	return reverseTransformedValue;
}

@end
