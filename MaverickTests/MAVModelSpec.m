//
//  MAVModelSpec.m
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MAVTestModel.h"

SpecBegin(MAVModel)

it(@"should have empty default values", ^{
	expect([MAVModel defaultValuesForKeys]).to.equal(@{});
});

describe(@"subclass", ^{
	it(@"should initialize with default values", ^{
		MAVTestModel *model = [[MAVTestModel alloc] init];
		expect(model).notTo.beNil();

		expect(model.name).to.beNil();
		expect(model.count).to.equal(1);

		NSDictionary *expectedValues = @{ @"username": NSNull.null, @"count": @"1" };
		expect(model.dictionaryRepresentation).to.equal(expectedValues);
	});

	it(@"should initialize with property values", ^{
		NSDictionary *values = @{ @"name": @"foobar", @"count": @(5) };

		MAVTestModel *model = [[MAVTestModel alloc] initWithPropertyKeysAndValues:values];
		expect(model).notTo.beNil();

		expect(model.name).to.equal(@"foobar");
		expect(model.count).to.equal(5);

		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});

	describe(@"with a dictionary of values", ^{
		NSDictionary *values = @{ @"username": @"foobar", @"count": @"5" };

		__block MAVTestModel *model;
		beforeEach(^{
			model = [[MAVTestModel alloc] initWithDictionary:values];
			expect(model).notTo.beNil();
		});

		it(@"should initialize with given values", ^{
			expect(model.name).to.equal(@"foobar");
			expect(model.count).to.equal(5);

			expect(model.dictionaryRepresentation).to.equal(values);
		});

		it(@"should compare equal to matching model", ^{
			expect(model).to.equal(model);

			MAVTestModel *matchingModel = [[MAVTestModel alloc] initWithDictionary:values];
			expect(model).to.equal(matchingModel);
			expect(model.hash).to.equal(matchingModel.hash);
		});

		it(@"should not compare equal to different model", ^{
			MAVTestModel *differentModel = [[MAVTestModel alloc] init];
			expect(model).notTo.equal(differentModel);
		});

		it(@"should implement <NSCopying>", ^{
			expect([model copy]).to.equal(model);
		});

		it(@"should implement <NSCoding>", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
			expect(data).notTo.beNil();

			MAVTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(model).to.equal(unarchivedModel);
		});
	});

	it(@"should fail to initialize if validation fails", ^{
		MAVTestModel *model = [[MAVTestModel alloc] initWithDictionary:@{ @"username": @"this is too long a name" }];
		expect(model).to.beNil();
	});

	describe(@"migration", ^{
		beforeAll(^{
			[MAVTestModel setModelVersion:0];
		});

		afterAll(^{
			[MAVTestModel setModelVersion:1];
		});

		NSDictionary *oldValues = @{ @"mav_name": @"foobar", @"mav_count": @"5" };
		NSDictionary *newValues = @{ @"username": @"M: foobar", @"count": @"5" };

		__block MAVTestModel *oldModel;
		beforeEach(^{
			oldModel = [[MAVTestModel alloc] initWithDictionary:oldValues];
			expect(oldModel).notTo.beNil();
		});

		it(@"should use an older model version for its dictionary representation", ^{
			expect(oldModel.dictionaryRepresentation).to.equal(oldValues);
		});

		it(@"should unarchive an older model version", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldModel];
			expect(data).notTo.beNil();

			[MAVTestModel setModelVersion:1];

			MAVTestModel *newModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(newModel).notTo.beNil();
			expect(newModel.dictionaryRepresentation).to.equal(newValues);
		});
	});

	it(@"should merge two models together", ^{
		MAVTestModel *target = [[MAVTestModel alloc] initWithDictionary:@{ @"username": @"foo", @"count": @"5" }];
		expect(target).notTo.beNil();

		MAVTestModel *source = [[MAVTestModel alloc] initWithDictionary:@{ @"username": @"bar", @"count": @"3" }];
		expect(source).notTo.beNil();

		MAVTestModel *merged = [target modelByMergingFromModel:source];
		expect(merged).notTo.beNil();

		expect(merged.name).to.equal(@"bar");
		expect(merged.count).to.equal(8);
	});
});

SpecEnd
