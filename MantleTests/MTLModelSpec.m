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

describe(@"MTLNewTestModel", ^{
	__block NSDictionary *values;
	__block MTLNewTestModel *otherModel;

	beforeEach(^{
		otherModel = [[MTLNewTestModel alloc] init];
		expect(otherModel).notTo.beNil();

		values = @{
			@"name": @"foo",
			@"count": @5,
			@"nestedName": @"bar",
			@"otherModel": otherModel
		};
	});

	it(@"should list properties in +propertyKeys", ^{
		NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", @"otherModel", nil];
		expect(MTLNewTestModel.propertyKeys).to.equal(expectedKeys);
	});

	it(@"should have default encoding behaviors", ^{
		NSDictionary *behaviors = [MTLNewTestModel encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:@"FakeFormat"];
		NSDictionary *expected = @{
			@"name": @(MTLModelEncodingBehaviorUnconditional),
			@"count": @(MTLModelEncodingBehaviorUnconditional),
			@"nestedName": @(MTLModelEncodingBehaviorUnconditional),
			@"otherModel": @(MTLModelEncodingBehaviorConditional),
		};

		expect(behaviors).to.equal(expected);
	});

	it(@"should initialize with default values", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] init];
		expect(model).notTo.beNil();

		expect(model.name).to.beNil();
		expect(model.count).to.equal(1);
		expect(model.nestedName).to.beNil();
		expect(model.otherModel).to.beNil();

		NSDictionary *expectedValues = @{ @"name": NSNull.null, @"count": @(1), @"nestedName": NSNull.null, @"otherModel": NSNull.null };
		expect(model.dictionaryValue).to.equal(expectedValues);
		expect([model dictionaryWithValuesForKeys:expectedValues.allKeys]).to.equal(expectedValues);
	});

	it(@"should initialize to default values with a nil dictionary", ^{
		MTLNewTestModel *dictionaryModel = [[MTLNewTestModel alloc] initWithDictionary:nil];
		expect(dictionaryModel).notTo.beNil();

		MTLNewTestModel *defaultModel = [[MTLNewTestModel alloc] init];
		expect(dictionaryModel).to.equal(defaultModel);
	});

	it(@"should initialize from a dictionary", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithDictionary:values];
		expect(model).notTo.beNil();

		expect(model.name).to.equal(@"foo");
		expect(model.count).to.equal(5);
		expect(model.nestedName).to.equal(@"bar");
		expect(model.otherModel).to.equal(otherModel);

		expect(model.dictionaryValue).to.equal(values);
		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});

	it(@"should compare equal to a matching model", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithDictionary:values];
		expect(model).to.equal(model);

		MTLNewTestModel *matchingModel = [[MTLNewTestModel alloc] initWithDictionary:values];
		expect(model).to.equal(matchingModel);
		expect(model.hash).to.equal(matchingModel.hash);
		expect(model.dictionaryValue).to.equal(matchingModel.dictionaryValue);
	});

	it(@"should not compare equal to different model", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithDictionary:values];
		MTLNewTestModel *differentModel = [[MTLNewTestModel alloc] init];

		expect(model).notTo.equal(differentModel);
		expect(model.dictionaryValue).notTo.equal(differentModel.dictionaryValue);
	});

	it(@"should implement <NSCopying>", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithDictionary:values];
		MTLNewTestModel *copiedModel = [model copy];
		expect(copiedModel).to.equal(model);
		expect(copiedModel).notTo.beIdenticalTo(model);
	});

	it(@"should fail to initialize if dictionary validation fails", ^{
		MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithDictionary:@{ @"name": @"this is too long a name" }];
		expect(model).to.beNil();
	});

	it(@"should merge two models together", ^{
		MTLNewTestModel *target = [[MTLNewTestModel alloc] initWithDictionary:@{ @"name": @"foo", @"count": @(5) }];
		expect(target).notTo.beNil();

		MTLNewTestModel *source = [[MTLNewTestModel alloc] initWithDictionary:@{ @"name": @"bar", @"count": @(3) }];
		expect(source).notTo.beNil();

		[target mergeValuesForKeysFromModel:source];

		expect(target.name).to.equal(@"bar");
		expect(target.count).to.equal(8);
	});

	describe(@"JSON external representation format", ^{
		it(@"should return an external representation", ^{
			MTLNewTestModel *model = [MTLNewTestModel modelWithDictionary:values];

			NSDictionary *externalRepresentation = @{
				@"username": @"foo",
				@"count": @"5",
				@"nested": @{ @"name": @"bar" }
			};

			expect([model externalRepresentationInFormat:MTLModelJSONFormat]).to.equal(externalRepresentation);
		});

		it(@"should initialize with an external representation", ^{
			NSDictionary *externalRepresentation = @{
				@"username": @"foo",
				@"nested": @{ @"name": @"bar" },
				@"count": @"5"
			};

			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:externalRepresentation inFormat:MTLModelJSONFormat];
			expect(model).notTo.beNil();

			expect(model.name).to.equal(@"foo");
			expect(model.count).to.equal(5);
			expect(model.nestedName).to.equal(@"bar");
			expect(model.otherModel).to.beNil();

			expect([model externalRepresentationInFormat:MTLModelJSONFormat]).to.equal(externalRepresentation);
		});

		it(@"should fail to initialize with a nil external representation", ^{
			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:nil inFormat:MTLModelJSONFormat];
			expect(model).to.beNil();
		});

		it(@"should ignore unrecognized key paths", ^{
			NSDictionary *externalRepresentation = @{
				@"foobar": @"buzz",
				@"count": @"5",
				@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
				@"_": NSNull.null,
				@"username": @"foo"
			};

			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:externalRepresentation inFormat:MTLModelJSONFormat];
			expect(model).notTo.beNil();

			expect(model.name).to.equal(@"foo");
			expect(model.count).to.equal(5);
			expect(model.nestedName).to.equal(@"bar");
			expect(model.otherModel).to.beNil();

			NSDictionary *expectedRepresentation = @{
				@"count": @"5",
				@"username": @"foo",
				@"nested": @{ @"name": @"bar" }
			};

			expect([model externalRepresentationInFormat:MTLModelJSONFormat]).to.equal(expectedRepresentation);
		});
	});

	describe(@"keyed archive external representation format", ^{
		it(@"should return an external representation", ^{
			MTLNewTestModel *model = [MTLNewTestModel modelWithDictionary:values];

			NSDictionary *externalRepresentation = @{
				@"name": @"foo",
				@"count": @5,
				@"otherModel": otherModel
			};

			expect([model externalRepresentationInFormat:MTLModelKeyedArchiveFormat]).to.equal(externalRepresentation);
		});

		it(@"should initialize with an external representation", ^{
			NSDictionary *externalRepresentation = @{
				@"name": @"foo",
				@"count": @5,
				@"otherModel": otherModel
			};

			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:externalRepresentation inFormat:MTLModelKeyedArchiveFormat];
			expect(model).notTo.beNil();

			expect(model.name).to.equal(@"foo");
			expect(model.count).to.equal(5);
			expect(model.nestedName).to.beNil();
			expect(model.otherModel).to.beIdenticalTo(otherModel);

			expect([model externalRepresentationInFormat:MTLModelKeyedArchiveFormat]).to.equal(externalRepresentation);
		});

		it(@"should fail to initialize with a nil external representation", ^{
			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:nil inFormat:MTLModelKeyedArchiveFormat];
			expect(model).to.beNil();
		});

		it(@"should ignore unrecognized key paths", ^{
			NSDictionary *externalRepresentation = @{
				@"foobar": @"buzz",
				@"count": @5,
				@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
				@"_": NSNull.null,
				@"name": @"foo",
				@"otherModel": otherModel
			};

			MTLNewTestModel *model = [[MTLNewTestModel alloc] initWithExternalRepresentation:externalRepresentation inFormat:MTLModelKeyedArchiveFormat];
			expect(model).notTo.beNil();

			expect(model.name).to.equal(@"foo");
			expect(model.count).to.equal(5);
			expect(model.nestedName).to.beNil();
			expect(model.otherModel).to.beIdenticalTo(otherModel);

			NSDictionary *expectedRepresentation = @{
				@"count": @5,
				@"name": @"foo",
				@"otherModel": otherModel
			};

			expect([model externalRepresentationInFormat:MTLModelKeyedArchiveFormat]).to.equal(expectedRepresentation);
		});

		describe(@"<NSCoding>", ^{
			__block MTLNewTestModel *model;

			beforeEach(^{
				model = [[MTLNewTestModel alloc] initWithDictionary:values];
				model.nestedName = nil;
				expect(model).notTo.beNil();
			});

			it(@"should skip conditional properties if not unconditionally encoded elsewhere", ^{
				NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
				expect(data).notTo.beNil();

				MTLNewTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
				expect(unarchivedModel.otherModel).to.beNil();

				model.otherModel = nil;
				expect(unarchivedModel).to.equal(model);
			});

			it(@"should encode conditional properties when unconditionally encoded elsewhere", ^{
				NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[ model, otherModel ]];
				expect(data).notTo.beNil();

				NSArray *models = [NSKeyedUnarchiver unarchiveObjectWithData:data];
				expect(models).notTo.beNil();
				expect(models.count).to.equal(2);

				MTLNewTestModel *unarchivedModel = models[0];
				expect(unarchivedModel.otherModel).notTo.beNil();
				expect(unarchivedModel).to.equal(model);
			});
		});
	});

	describe(@"migration", ^{
		beforeEach(^{
			[MTLNewTestModel setModelVersion:0];
		});

		afterEach(^{
			[MTLNewTestModel setModelVersion:1];
		});

		NSDictionary *oldValues = @{ @"old_name": @"some name", @"count": @5, @"otherModel": NSNull.null };
		NSDictionary *newValues = @{ @"name": @"some name", @"count": @5, @"otherModel": NSNull.null };

		__block MTLNewTestModel *oldModel;
		beforeEach(^{
			oldModel = [[MTLNewTestModel alloc] initWithExternalRepresentation:oldValues inFormat:MTLModelKeyedArchiveFormat];
			expect(oldModel).notTo.beNil();
		});

		it(@"should use an older model version for its external representation", ^{
			expect([oldModel externalRepresentationInFormat:MTLModelKeyedArchiveFormat]).to.equal(oldValues);
		});

		it(@"should unarchive an older model version", ^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldModel];
			expect(data).notTo.beNil();

			[MTLNewTestModel setModelVersion:1];

			MTLNewTestModel *newModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(newModel).notTo.beNil();
			expect([newModel externalRepresentationInFormat:MTLModelKeyedArchiveFormat]).to.equal(newValues);
		});
	});
});

describe(@"MTLOldTestModel", ^{
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated"

	it(@"should list all properties in +propertyKeys", ^{
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
		beforeEach(^{
			[MTLOldTestModel setModelVersion:0];
		});

		afterEach(^{
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

	#pragma clang diagnostic pop
});

SpecEnd
