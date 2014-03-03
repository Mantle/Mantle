//
//  MTLModelValidationSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

#import "MTLModel.h"
#import "MTLError.h"

SpecBegin(MTLModelValidation)

it(@"should fail with incorrect values", ^{
	MTLValidationModel *model = [[MTLValidationModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	expect(success).to.beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameMissing);
});

#if !defined(OBJC_HIDE_64) && TARGET_OS_IPHONE && __LP64__
it(@"should fail when boolean specified as a nubmer", ^{
#else
it(@"should succed even if boolean specified as a nubmer", ^{
#endif
	NSError *error = nil;
	NSDictionary *dictionary = @{
		// sadly, I found no way to validate nubmers assignment to a BOOL property
		// on pre-64-bit iOS, since BOOL is defined as a signed char
		@"boolean" : @1
	};

	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:dictionary
																		 error:&error];

// Not sure if this a valid approach but, given that the test would be run on
// 64-bit iOS, the result would be different
#if !defined(OBJC_HIDE_64) && TARGET_OS_IPHONE && __LP64__
	expect(model).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLModelErrorDomain);
	expect(error.code).to.equal(MTLModelValidationError);
	expect(model.boolean).to.beFalsy();
#else
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	expect(model.boolean).to.beTruthy();
#endif
});

it(@"should fail when incorrecte structure type used", ^{
	CGPoint point = (CGPoint){ 20, 20 };
	
	NSError *error = nil;
	NSDictionary *dictionary = @{
		@"structure" : [NSValue value:&point
						 withObjCType:@encode(CGPoint)]
	};
	
	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:dictionary
																		 error:&error];
	
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLModelErrorDomain);
	expect(error.code).to.equal(MTLModelValidationError);
	expect(model).to.beNil();
});

it(@"should succeed when correcte structure type used", ^{
	MTLTestStructure structure = (MTLTestStructure){ 42, YES };
	
	NSError *error = nil;
	NSDictionary *dictionary = @{
		@"structure" : [NSValue value:&structure
						 withObjCType:@encode(MTLTestStructure)]
	};
	
	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:dictionary
																		 error:&error];
	
	expect(error).to.beNil();
	expect(model).notTo.beNil();
	expect(model.structure.count == structure.count &&
		   model.structure.isOn == structure.isOn).to.beTruthy();
});


it(@"should succeed with correct values", ^{
	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:@{ @"name": @"valid" } error:NULL];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	expect(success).to.beTruthy();

	expect(error).to.beNil();
});

it(@"should apply values returned from -validateValue:error:", ^{
	MTLSelfValidatingModel *model = [[MTLSelfValidatingModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	expect(success).to.beTruthy();

	expect(model.name).to.equal(@"foobar");

	expect(error).to.beNil();
});

SpecEnd
