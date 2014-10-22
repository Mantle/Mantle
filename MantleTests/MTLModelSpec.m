//
//  MTLModelSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

#import "MTLTestModel.h"

QuickSpecBegin(MTLModelSpec)

it(@"should not loop infinitely in +propertyKeys without any properties", ^{
	expect(MTLEmptyTestModel.propertyKeys).to(equal([NSSet set]));
});

it(@"should not include dynamic readonly properties in +propertyKeys", ^{
	NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", @"weakModel", nil];
	expect(MTLTestModel.propertyKeys).to(equal(expectedKeys));
});

it(@"should initialize with default values", ^{
	MTLTestModel *model = [[MTLTestModel alloc] init];
	expect(model).notTo(beNil());

	expect(model.name).to(beNil());
	expect(@(model.count)).to(equal(@1));

	NSDictionary *expectedValues = @{
		@"name": NSNull.null,
		@"count": @(1),
		@"nestedName": NSNull.null,
		@"weakModel": NSNull.null,
	};

	expect(model.dictionaryValue).to(equal(expectedValues));
	expect([model dictionaryWithValuesForKeys:expectedValues.allKeys]).to(equal(expectedValues));
});

it(@"should initialize to default values with a nil dictionary", ^{
	NSError *error = nil;
	MTLTestModel *dictionaryModel = [[MTLTestModel alloc] initWithDictionary:nil error:&error];
	expect(dictionaryModel).notTo(beNil());
	expect(error).to(beNil());

	MTLTestModel *defaultModel = [[MTLTestModel alloc] init];
	expect(dictionaryModel).to(equal(defaultModel));
});

describe(@"with a dictionary of values", ^{
	__block MTLEmptyTestModel *emptyModel;
	__block NSDictionary *values;
	__block MTLTestModel *model;

	beforeEach(^{
		emptyModel = [[MTLEmptyTestModel alloc] init];
		expect(emptyModel).notTo(beNil());

		values = @{
			@"name": @"foobar",
			@"count": @(5),
			@"nestedName": @"fuzzbuzz",
			@"weakModel": emptyModel,
		};

		NSError *error = nil;
		model = [[MTLTestModel alloc] initWithDictionary:values error:&error];
		expect(model).notTo(beNil());
		expect(error).to(beNil());
	});

	it(@"should initialize with the given values", ^{
		expect(model.name).to(equal(@"foobar"));
		expect(@(model.count)).to(equal(@5));
		expect(model.nestedName).to(equal(@"fuzzbuzz"));
		expect(model.weakModel).to(equal(emptyModel));

		expect(model.dictionaryValue).to(equal(values));
		expect([model dictionaryWithValuesForKeys:values.allKeys]).to(equal(values));
	});

	it(@"should compare equal to a matching model", ^{
		expect(model).to(equal(model));

		MTLTestModel *matchingModel = [[MTLTestModel alloc] initWithDictionary:values error:NULL];
		expect(model).to(equal(matchingModel));
		expect(@(model.hash)).to(equal(@(matchingModel.hash)));
		expect(model.dictionaryValue).to(equal(matchingModel.dictionaryValue));
	});

	it(@"should not compare equal to different model", ^{
		MTLTestModel *differentModel = [[MTLTestModel alloc] init];
		expect(model).notTo(equal(differentModel));
		expect(model.dictionaryValue).notTo(equal(differentModel.dictionaryValue));
	});

	it(@"should implement <NSCopying>", ^{
		MTLTestModel *copiedModel = [model copy];
		expect(copiedModel).to(equal(model));
		expect(copiedModel).notTo(beIdenticalTo(model));
	});
});

it(@"should fail to initialize if dictionary validation fails", ^{
	NSError *error = nil;
	MTLTestModel *model = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"this is too long a name" } error:&error];
	expect(model).to(beNil());

	expect(error).notTo(beNil());
	expect(error.domain).to(equal(MTLTestModelErrorDomain));
	expect(@(error.code)).to(equal(@(MTLTestModelNameTooLong)));
});

it(@"should merge two models together", ^{
	MTLTestModel *target = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"foo", @"count": @(5) } error:NULL];
	expect(target).notTo(beNil());

	MTLTestModel *source = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"bar", @"count": @(3) } error:NULL];
	expect(source).notTo(beNil());

	[target mergeValuesForKeysFromModel:source];

	expect(target.name).to(equal(@"bar"));
	expect(@(target.count)).to(equal(@8));
});

describe(@"merging with model subclasses", ^{
	__block MTLTestModel *superclass;
	__block MTLSubclassTestModel *subclass;

	beforeEach(^{
		superclass = [MTLTestModel modelWithDictionary:@{
			@"name": @"foo",
			@"count": @5
		} error:NULL];

		expect(superclass).notTo(beNil());

		subclass = [MTLSubclassTestModel modelWithDictionary:@{
			@"name": @"bar",
			@"count": @3,
			@"generation": @1,
			@"role": @"subclass"
		} error:NULL];

		expect(subclass).notTo(beNil());
	});

	it(@"should merge from subclass model", ^{
		[superclass mergeValuesForKeysFromModel:subclass];

		expect(superclass.name).to(equal(@"bar"));
		expect(@(superclass.count)).to(equal(@8));
	});

	it(@"should merge from superclass model", ^{
		[subclass mergeValuesForKeysFromModel:superclass];

		expect(subclass.name).to(equal(@"foo"));
		expect(@(subclass.count)).to(equal(@8));
		expect(subclass.generation).to(equal(@1));
		expect(subclass.role).to(equal(@"subclass"));
	});
});

QuickSpecEnd
