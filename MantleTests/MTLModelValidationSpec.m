//
//  MTLModelValidationSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

#import "MTLModel+Validation.h"

SpecBegin(MTLModelValidation)

it(@"should fail with incorrect values", ^{
	MTLValidationModel *model = [[MTLValidationModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validateWithError:&error];
	expect(success).to.beFalsy();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameMissing);
});

it(@"should succeed with correct values", ^{
	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:@{ @"name": @"valid" } error:NULL];

	NSError *error = nil;
	BOOL success = [model validateWithError:&error];
	expect(success).to.beTruthy();

	expect(error).to.beNil();
});

it(@"should apply values returned from -validateValue:error:", ^{
	MTLSelfValidatingModel *model = [[MTLSelfValidatingModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validateWithError:&error];
	expect(success).to.beTruthy();

	expect(model.name).to.equal(@"foobar");

	expect(error).to.beNil();
});

SpecEnd
