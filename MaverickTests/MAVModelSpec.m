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

		NSDictionary *expectedValues = @{ @"username": [NSNull null], @"count": @(1) };
		expect(model.dictionaryRepresentation).to.equal(expectedValues);
	});

	describe(@"with a dictionary of values", ^{
		NSDictionary *values = @{ @"username": @"foobar", @"count": @(5) };

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

	describe(@"validation", ^{
		it(@"should fail to initialize if validation fails", ^{
			MAVTestModel *model = [[MAVTestModel alloc] initWithDictionary:@{ @"username": @"this is too long a name" }];
			expect(model).to.beNil();
		});

		it(@"should use values returned by validation", ^{
			// Our KVC validation method should parse the string and turn it
			// into a number.
			MAVTestModel *model = [[MAVTestModel alloc] initWithDictionary:@{ @"count": @"50" }];
			expect(model).notTo.beNil();
			expect(model.count).to.equal(50);
		});
	});
});

SpecEnd
