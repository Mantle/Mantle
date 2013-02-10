//
//  MTLModelSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLModel)

describe(@"subclass", ^{
	it(@"should not include dynamic readonly properties in +propertyKeys", ^{
		NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", nil];
		expect(MTLOldTestModel.propertyKeys).to.equal(expectedKeys);
	});

	it(@"should initialize with default values", ^{
		MTLOldTestModel *model = [[MTLOldTestModel alloc] init];
		expect(model).notTo.beNil();

		expect(model.name).to.beNil();
		expect(model.count).to.equal(1);

		NSDictionary *expectedValues = @{ @"name": NSNull.null, @"count": @(1), @"nestedName": NSNull.null };
		expect(model.dictionaryValue).to.equal(expectedValues);
		expect([model dictionaryWithValuesForKeys:expectedValues.allKeys]).to.equal(expectedValues);
	});

	it(@"should initialize to default values with a nil dictionary", ^{
		MTLOldTestModel *dictionaryModel = [[MTLOldTestModel alloc] initWithDictionary:nil];
		expect(dictionaryModel).notTo.beNil();

		MTLOldTestModel *defaultModel = [[MTLOldTestModel alloc] init];
		expect(dictionaryModel).to.equal(defaultModel);
	});

	it(@"should initialize with an external representation", ^{
		NSDictionary *values = @{ @"username": NSNull.null, @"count": @"5" };

		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:values];
		expect(model).notTo.beNil();

		expect(model.name).to.beNil();
		expect(model.count).to.equal(5);

		expect(model.externalRepresentation).to.equal(values);
	});

	it(@"should initialize nested key paths from an external representation", ^{
		NSDictionary *values = @{
			@"username": @"foo",
			@"nested": @{ @"name": @"bar" },
			@"count": @"0"
		};

		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:values];
		expect(model).notTo.beNil();

		expect(model.name).to.equal(@"foo");
		expect(model.count).to.equal(0);
		expect(model.nestedName).to.equal(@"bar");

		expect(model.externalRepresentation).to.equal(values);
	});

	it(@"should ignore unrecognized nested key paths in an external representation", ^{
		NSDictionary *values = @{
			@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null }
		};

		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:values];
		expect(model).notTo.beNil();
		expect(model.nestedName).to.equal(@"bar");
	});

	it(@"should fail to initialize with a nil external representation", ^{
		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:nil];
		expect(model).to.beNil();
	});

	it(@"should ignore unrecognized external representation keys", ^{
		NSDictionary *values = @{ @"foobar": @"foo", @"count": @"2", @"_": NSNull.null, @"username": @"buzz" };

		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:values];
		expect(model).notTo.beNil();

		expect(model.name).to.equal(@"buzz");
		expect(model.count).to.equal(2);

		NSDictionary *expectedValues = @{ @"count": @"2", @"username": @"buzz" };
		expect(model.externalRepresentation).to.equal(expectedValues);
	});

	describe(@"with a dictionary of values", ^{
		NSDictionary *values = @{ @"name": @"foobar", @"count": @(5), @"nestedName": @"fuzzbuzz" };

		__block MTLOldTestModel *model;
		beforeEach(^{
			model = [[MTLOldTestModel alloc] initWithDictionary:values];
			expect(model).notTo.beNil();
		});

		it(@"should initialize with the given values", ^{
			expect(model.name).to.equal(@"foobar");
			expect(model.count).to.equal(5);

			expect(model.dictionaryValue).to.equal(values);
			expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
		});

		it(@"should have an external representation", ^{
			NSDictionary *expectedValues = @{
				@"username": @"foobar",
				@"count": @"5",
				@"nested": @{ @"name": @"fuzzbuzz" }
			};

			expect(model.externalRepresentation).to.equal(expectedValues);
		});

		it(@"should compare equal to a matching model", ^{
			expect(model).to.equal(model);

			MTLOldTestModel *matchingModel = [[MTLOldTestModel alloc] initWithDictionary:values];
			expect(model).to.equal(matchingModel);
			expect(model.hash).to.equal(matchingModel.hash);
			expect(model.dictionaryValue).to.equal(matchingModel.dictionaryValue);
			expect(model.externalRepresentation).to.equal(matchingModel.externalRepresentation);
		});

		it(@"should not compare equal to different model", ^{
			MTLOldTestModel *differentModel = [[MTLOldTestModel alloc] init];
			expect(model).notTo.equal(differentModel);
			expect(model.dictionaryValue).notTo.equal(differentModel.dictionaryValue);
			expect(model.externalRepresentation).notTo.equal(differentModel.externalRepresentation);
		});

		it(@"should implement <NSCopying>", ^{
			MTLOldTestModel *copiedModel = [model copy];
			expect(copiedModel).to.equal(model);
			expect(copiedModel == model).to.beFalsy();
		});

		it(@"should implement <NSCoding>", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
			expect(data).notTo.beNil();

			MTLOldTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(model).to.equal(unarchivedModel);
		});
	});

	it(@"should fail to initialize if dictionary validation fails", ^{
		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithDictionary:@{ @"name": @"this is too long a name" }];
		expect(model).to.beNil();
	});

	it(@"should fail to initialize if external representation validation fails", ^{
		MTLOldTestModel *model = [[MTLOldTestModel alloc] initWithExternalRepresentation:@{ @"username": @"this is too long a name" }];
		expect(model).to.beNil();
	});

	describe(@"migration", ^{
		beforeAll(^{
			[MTLOldTestModel setModelVersion:0];
		});

		afterAll(^{
			[MTLOldTestModel setModelVersion:1];
		});

		NSDictionary *oldValues = @{ @"mtl_name": @"foobar", @"mtl_count": @"5" };
		NSDictionary *newValues = @{ @"username": @"M: foobar", @"count": @"5" };

		__block MTLOldTestModel *oldModel;
		beforeEach(^{
			oldModel = [[MTLOldTestModel alloc] initWithExternalRepresentation:oldValues];
			expect(oldModel).notTo.beNil();
		});

		it(@"should use an older model version for its external representation", ^{
			expect(oldModel.externalRepresentation).to.equal(oldValues);
		});

		it(@"should unarchive an older model version", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldModel];
			expect(data).notTo.beNil();

			[MTLOldTestModel setModelVersion:1];

			MTLOldTestModel *newModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(newModel).notTo.beNil();
			expect(newModel.externalRepresentation).to.equal(newValues);
		});
	});

	it(@"should merge two models together", ^{
		MTLOldTestModel *target = [[MTLOldTestModel alloc] initWithDictionary:@{ @"name": @"foo", @"count": @(5) }];
		expect(target).notTo.beNil();

		MTLOldTestModel *source = [[MTLOldTestModel alloc] initWithDictionary:@{ @"name": @"bar", @"count": @(3) }];
		expect(source).notTo.beNil();

		[target mergeValuesForKeysFromModel:source];

		expect(target.name).to.equal(@"bar");
		expect(target.count).to.equal(8);
	});

	it(@"should not loop infinitely in +propertyKeys without any properties", ^{
		expect(MTLEmptyTestModel.propertyKeys).to.equal([NSSet set]);
	});
});

SpecEnd
