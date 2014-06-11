//
//  MTLErrorModelExceptionSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"

SpecBegin(MTLErrorModelException)

describe(@"+mtl_modelErrorWithException:", ^{
	it(@"should return a new error for that exception", ^{
		NSException *exception = [NSException exceptionWithName:@"MTLTestException" reason:@"Just Testing" userInfo:nil];
		
		NSError *error = [NSError mtl_modelErrorWithException:exception];
		
		expect(error).toNot.beNil();
		expect(error.localizedDescription).to.equal(@"Just Testing");
		expect(error.localizedFailureReason).to.equal(@"Just Testing");
	});
});

SpecEnd
