//
//  MTLModelSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLModel)

it(@"should not loop infinitely in +propertyKeys without any properties", ^{
	expect(MTLEmptyTestModel.propertyKeys).to.equal([NSSet set]);
});

it(@"should not include dynamic readonly properties in +propertyKeys", ^{
	NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", @"weakModel", nil];
	expect(MTLTestModel.propertyKeys).to.equal(expectedKeys);
});

it(@"should initialize with default values", ^{
	MTLTestModel *model = [[MTLTestModel alloc] init];
	expect(model).notTo.beNil();

	expect(model.name).to.beNil();
	expect(model.count).to.equal(1);

	NSDictionary *expectedValues = @{
		@"name": NSNull.null,
		@"count": @(1),
		@"nestedName": NSNull.null,
		@"weakModel": NSNull.null,
	};

	expect(model.dictionaryValue).to.equal(expectedValues);
	expect([model dictionaryWithValuesForKeys:expectedValues.allKeys]).to.equal(expectedValues);
});

it(@"should initialize to default values with a nil dictionary", ^{
	MTLTestModel *dictionaryModel = [[MTLTestModel alloc] initWithDictionary:nil];
	expect(dictionaryModel).notTo.beNil();

	MTLTestModel *defaultModel = [[MTLTestModel alloc] init];
	expect(dictionaryModel).to.equal(defaultModel);
});

describe(@"with a dictionary of values", ^{
	__block MTLEmptyTestModel *emptyModel;
	__block NSDictionary *values;
	__block MTLTestModel *model;

	beforeEach(^{
		emptyModel = [[MTLEmptyTestModel alloc] init];
		expect(emptyModel).notTo.beNil();

		values = @{
			@"name": @"foobar",
			@"count": @(5),
			@"nestedName": @"fuzzbuzz",
			@"weakModel": emptyModel,
		};

		model = [[MTLTestModel alloc] initWithDictionary:values];
		expect(model).notTo.beNil();
	});

	it(@"should initialize with the given values", ^{
		expect(model.name).to.equal(@"foobar");
		expect(model.count).to.equal(5);
		expect(model.nestedName).to.equal(@"fuzzbuzz");
		expect(model.weakModel).to.equal(emptyModel);

		expect(model.dictionaryValue).to.equal(values);
		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});

	it(@"should compare equal to a matching model", ^{
		expect(model).to.equal(model);

		MTLTestModel *matchingModel = [[MTLTestModel alloc] initWithDictionary:values];
		expect(model).to.equal(matchingModel);
		expect(model.hash).to.equal(matchingModel.hash);
		expect(model.dictionaryValue).to.equal(matchingModel.dictionaryValue);
	});

	it(@"should not compare equal to different model", ^{
		MTLTestModel *differentModel = [[MTLTestModel alloc] init];
		expect(model).notTo.equal(differentModel);
		expect(model.dictionaryValue).notTo.equal(differentModel.dictionaryValue);
	});

	it(@"should implement <NSCopying>", ^{
		MTLTestModel *copiedModel = [model copy];
		expect(copiedModel).to.equal(model);
		expect(copiedModel).notTo.beIdenticalTo(model);
	});
});

it(@"should fail to initialize if dictionary validation fails", ^{
	MTLTestModel *model = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"this is too long a name" }];
	expect(model).to.beNil();
});

it(@"should merge two models together", ^{
	MTLTestModel *target = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"foo", @"count": @(5) }];
	expect(target).notTo.beNil();

	MTLTestModel *source = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"bar", @"count": @(3) }];
	expect(source).notTo.beNil();

	[target mergeValuesForKeysFromModel:source];

	expect(target.name).to.equal(@"bar");
	expect(target.count).to.equal(8);
});

SpecEnd
