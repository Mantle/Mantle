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

		NSDictionary *expectedValues = @{ @"name": [NSNull null], @"count": @(1) };
		expect(model.dictionaryRepresentation).to.equal(expectedValues);
	});

	describe(@"with a dictionary of values", ^{
		NSDictionary *values = @{ @"name": @"foobar", @"count": @(5) };

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
});

SpecEnd
