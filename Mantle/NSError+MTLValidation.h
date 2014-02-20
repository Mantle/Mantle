//
//  NSError+MTLValidation.h
//  Mantle
//
//  Created by Sasha Zats on 2/13/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (MTLValidation)

// Creates an umbrella error from the array of validation errors
//
// errors - An array of errors to wrap into one groupping error.
//          Must be not nil.
//
// Returns an umbrella error containing an array of errors under the
// MTLDetailedErrorsKey key in the userInfo dictionary or the first error
// if passed array contains only one error.
+ (instancetype)mtl_umbrellaErrorWithErrors:(NSArray *)errors;

// Creates a new error for an exception that occured during validating an
// MTLModel.
//
// property -     The property caused validation error.
//                This argument must not be nil.
//
// expectedType - A string representing class or a primitive type of the
//                expected value.
//
// receivedType - A string representing class or a primitive type of the
//                received value.
//
// Returns a validation error.
+ (instancetype)mtl_validationErrorForProperty:(NSString *)property
                                  expectedType:(NSString *)expectedType
                                  receivedType:(NSString *)receivedType;

@end
