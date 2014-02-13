//
//  MTLPropertyInspectionAdditionSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 04/01/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

#import "NSObject+MTLPropertyInspection.h"

SpecBegin(MTLPropertyInspectionAdditions)

describe(@"+mtl_classOfPropertyWithKey:", ^{
	it(@"should return the class of a property", ^{
		expect([MTLTestModel mtl_classOfPropertyWithKey:@"weakModel"]).to.equal(MTLEmptyTestModel.class);
	});

	it(@"should return nil for primitive properties", ^{
		expect([MTLTestModel mtl_classOfPropertyWithKey:@"count"]).to.beNil();
	});

	it(@"should return nil for non-existant properties", ^{
		expect([MTLTestModel mtl_classOfPropertyWithKey:@"non-existant"]).to.beNil();
	});
});

describe(@"+mtl_objCTypeOfPropertyWithKey:", ^{
	it(@"should return the type-encoding of a property", ^{
		char *actual = [MTLTestModel mtl_copyObjCTypeOfPropertyWithKey:@"count"];

		const char *expected = @encode(NSUInteger);

		expect(strcmp(actual, expected) == 0).to.beTruthy();

		free(actual);
	});

	it(@"should return NULL for non-existant properties", ^{
		expect([MTLTestModel mtl_classOfPropertyWithKey:@"non-existant"]).to.beNull();
	});
});

SpecEnd
