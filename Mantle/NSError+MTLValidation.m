//
//  NSError+MTLValidation.m
//  Mantle
//
//  Created by Sasha Zats on 2/13/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSError+MTLValidation.h"

#import "MTLError.h"

@implementation NSError (MTLValidation)

+ (instancetype)mtl_umbrellaErrorWithErrors:(NSArray *)errors {
	NSParameterAssert(errors);
	if ([errors count] == 1) {
		return [errors firstObject];
	}
	
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey : @"Several validation error occured",
		MTLDetailedErrorsKey : errors
	};
	return [NSError errorWithDomain:MTLModelErrorDomain
							   code:MTLModelValidationError
						   userInfo:userInfo];
	
}

+ (instancetype)mtl_validationErrorForProperty:(NSString *)property
                                  expectedType:(NSString *)expectedType
                                  receivedType:(NSString *)receivedType {
	NSParameterAssert(property);
	NSParameterAssert(expectedType);
	NSParameterAssert(receivedType);

	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Type validation for property \"%@\" failed. Expected value of type \"%@\", received value of type \"%@\"", property, expectedType, receivedType]
	};	
	return [NSError errorWithDomain:MTLModelErrorDomain
							   code:MTLModelValidationError
						   userInfo:userInfo];
}

@end
