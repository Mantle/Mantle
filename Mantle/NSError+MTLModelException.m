//
//  NSError+MTLModelException.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

#import "NSError+MTLModelException.h"
#import "MTLError.h"

@implementation NSError (MTLModelException)

+ (instancetype)mtl_modelErrorWithException:(NSException *)exception {
	NSParameterAssert(exception != nil);

	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey: exception.description,
		NSLocalizedFailureReasonErrorKey: exception.reason,
		MTLModelThrownExceptionErrorKey: exception
	};

	return [NSError errorWithDomain:MTLModelErrorDomain code:MTLModelErrorExceptionThrown userInfo:userInfo];
}

@end
