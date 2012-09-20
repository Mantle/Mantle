//
//  MTLModelSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLModel)

it(@"should have empty default values", ^{
	expect([MTLModel defaultValuesForKeys]).to.equal(@{});
});

describe(@"subclass", ^{
	it(@"should initialize with default values", ^{
		MTLTestModel *model = [[MTLTestModel alloc] init];
		expect(model).notTo.beNil();

		expect(model.name).to.beNil();
		expect(model.count).to.equal(1);

		NSDictionary *expectedValues = @{ @"username": NSNull.null, @"count": @"1" };
		expect(model.dictionaryRepresentation).to.equal(expectedValues);
	});

	it(@"should initialize with property values", ^{
		NSDictionary *values = @{ @"name": @"foobar", @"count": @(5) };

		MTLTestModel *model = [[MTLTestModel alloc] initWithPropertyKeysAndValues:values];
		expect(model).notTo.beNil();

		expect(model.name).to.equal(@"foobar");
		expect(model.count).to.equal(5);

		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});

	describe(@"with a dictionary of values", ^{
		NSDictionary *values = @{ @"username": @"foobar", @"count": @"5" };

		__block MTLTestModel *model;
		beforeEach(^{
			model = [[MTLTestModel alloc] initWithDictionary:values];
			expect(model).notTo.beNil();
		});

		it(@"should initialize with given values", ^{
			expect(model.name).to.equal(@"foobar");
			expect(model.count).to.equal(5);

			expect(model.dictionaryRepresentation).to.equal(values);
		});

		it(@"should compare equal to matching model", ^{
			expect(model).to.equal(model);

			MTLTestModel *matchingModel = [[MTLTestModel alloc] initWithDictionary:values];
			expect(model).to.equal(matchingModel);
			expect(model.hash).to.equal(matchingModel.hash);
		});

		it(@"should not compare equal to different model", ^{
			MTLTestModel *differentModel = [[MTLTestModel alloc] init];
			expect(model).notTo.equal(differentModel);
		});

		it(@"should implement <NSCopying>", ^{
			expect([model copy]).to.equal(model);
		});

		it(@"should implement <NSCoding>", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
			expect(data).notTo.beNil();

			MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(model).to.equal(unarchivedModel);
		});
	});

	it(@"should fail to initialize if validation fails", ^{
		MTLTestModel *model = [[MTLTestModel alloc] initWithDictionary:@{ @"username": @"this is too long a name" }];
		expect(model).to.beNil();
	});

	describe(@"migration", ^{
		beforeAll(^{
			[MTLTestModel setModelVersion:0];
		});

		afterAll(^{
			[MTLTestModel setModelVersion:1];
		});

		NSDictionary *oldValues = @{ @"mtl_name": @"foobar", @"mtl_count": @"5" };
		NSDictionary *newValues = @{ @"username": @"M: foobar", @"count": @"5" };

		__block MTLTestModel *oldModel;
		beforeEach(^{
			oldModel = [[MTLTestModel alloc] initWithDictionary:oldValues];
			expect(oldModel).notTo.beNil();
		});

		it(@"should use an older model version for its dictionary representation", ^{
			expect(oldModel.dictionaryRepresentation).to.equal(oldValues);
		});

		it(@"should unarchive an older model version", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldModel];
			expect(data).notTo.beNil();

			[MTLTestModel setModelVersion:1];

			MTLTestModel *newModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(newModel).notTo.beNil();
			expect(newModel.dictionaryRepresentation).to.equal(newValues);
		});
	});

	it(@"should merge two models together", ^{
		MTLTestModel *target = [[MTLTestModel alloc] initWithDictionary:@{ @"username": @"foo", @"count": @"5" }];
		expect(target).notTo.beNil();

		MTLTestModel *source = [[MTLTestModel alloc] initWithDictionary:@{ @"username": @"bar", @"count": @"3" }];
		expect(source).notTo.beNil();

		MTLTestModel *merged = [target modelByMergingFromModel:source];
		expect(merged).notTo.beNil();

		expect(merged.name).to.equal(@"bar");
		expect(merged.count).to.equal(8);
	});
});

SpecEnd
