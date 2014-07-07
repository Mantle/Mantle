//
//  MTLJSONAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"
#import "MTLTestJSONAdapter.h"

SpecBegin(MTLJSONAdapter)

it(@"should initialize with a model class", ^{
	NSDictionary *values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};

	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModelClass:MTLTestModel.class];
	expect(adapter).notTo.beNil();

	NSError *error = nil;
	MTLTestModel *model = [adapter modelFromJSONDictionary:values error:&error];
	expect(error).to.beNil();

	expect(model).notTo.beNil();
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	__block NSError *serializationError;
	expect([adapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(JSONDictionary);
	expect(serializationError).to.beNil();
});

it(@"should initialize nested key paths from JSON", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	__block NSError *serializationError;
	expect([MTLJSONAdapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(values);
	expect(serializationError).to.beNil();
});

it(@"it should initialize properties with multiple key paths from JSON", ^{
	NSDictionary *values = @{
		@"location": @20,
		@"length": @12,
		@"nested": @{
			@"location": @12,
			@"length": @34
		}
	};

	NSError *error = nil;
	MTLMultiKeypathModel *model = [MTLJSONAdapter modelOfClass:MTLMultiKeypathModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.range.location).to.equal(20);
	expect(model.range.length).to.equal(12);

	expect(model.nestedRange.location).to.equal(12);
	expect(model.nestedRange.length).to.equal(34);

	__block NSError *serializationError;
	expect([MTLJSONAdapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(values);
	expect(serializationError).to.beNil();
});

it(@"should return nil and error with an invalid key path from JSON",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should not support key paths across arrays", ^{
	NSDictionary *values = @{
		@"users": @[
			@{
				@"name": @"foo"
			},
			@{
				@"name": @"bar"
			},
			@{
				@"name": @"baz"
			}
		]
	};

	NSError *error = nil;
	MTLArrayTestModel *model = [MTLJSONAdapter modelOfClass:MTLArrayTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();
	expect(error).notTo.beNil();

	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should initialize without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": NSNull.null,
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.beNil();
});

it(@"should ignore unrecognized JSON keys", ^{
	NSDictionary *values = @{
		@"foobar": @"foo",
		@"count": @"2",
		@"_": NSNull.null,
		@"username": @"buzz",
		@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to initialize if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
		@"username": @"this is too long a name",
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameTooLong);
});

it(@"should implicitly transform URLs", ^{
	MTLURLModel *model = [[MTLURLModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	expect(JSONDictionary[@"URL"]).to.equal(@"http://github.com");
	expect(error).to.beNil();
});

it(@"should implicitly transform BOOLs", ^{
	MTLBoolModel *model = [[MTLBoolModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	expect(JSONDictionary[@"flag"]).to.beIdenticalTo((id)kCFBooleanFalse);
	expect(error).to.beNil();
});

it(@"should not invoke implicit transformers for property keys not actually backed by properties", ^{
	MTLNonPropertyModel *model = [[MTLNonPropertyModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	expect(error).to.beNil();
	expect(JSONDictionary[@"homepage"]).to.equal(model.homepage);
});

it(@"should fail to initialize if JSON transformer fails", ^{
	NSDictionary *values = @{
		@"URL": @666,
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLURLModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();
	expect(error.domain).to.equal(MTLTransformerErrorHandlingErrorDomain);
	expect(error.code).to.equal(MTLTransformerErrorHandlingErrorInvalidInput);
	expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to.equal(@666);
});

it(@"should fail to deserialize if the JSON types don't match the properties", ^{
	NSDictionary *values = @{
		@"flag": @"Potentially"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLBoolModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();

	expect(error.domain).to.equal(MTLTransformerErrorHandlingErrorDomain);
	expect(error.code).to.equal(MTLTransformerErrorHandlingErrorInvalidInput);
	expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to.equal(@"Potentially");
});

it(@"should allow subclasses to filter serialized property keys", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null }
	};

	MTLTestJSONAdapter *adapter = [[MTLTestJSONAdapter alloc] initWithModelClass:MTLTestModel.class];

	NSError *error;
	MTLTestModel *model = [adapter modelFromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	NSDictionary *complete = [adapter JSONDictionaryFromModel:model error:&error];

	expect(complete).to.equal(values);
	expect(error).to.beNil();

	adapter.ignoredPropertyKeys = [NSSet setWithObjects:@"count", @"nestedName", nil];

	NSDictionary *partial = [adapter JSONDictionaryFromModel:model error:&error];

	expect(partial).to.equal(@{ @"username": @"foo" });
	expect(error).to.beNil();
});

it(@"should accept any object for id properties", ^{
	NSDictionary *values = @{
		@"anyObject": @"Not an NSValue"
	};

	NSError *error = nil;
	MTLIDModel *model = [MTLJSONAdapter modelOfClass:MTLIDModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(model.anyObject).to.equal(@"Not an NSValue");

	expect(error.domain).to.beNil();
});

it(@"should fail to serialize if a JSON transformer errors", ^{
	MTLURLModel *model = [[MTLURLModel alloc] init];

	[model setValue:@"totallyNotAnNSURL" forKey:@"URL"];

	NSError *error;
	NSDictionary *dictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
	expect(dictionary).to.beNil();
	expect(error.domain).to.equal(MTLTransformerErrorHandlingErrorDomain);
	expect(error.code).to.equal(MTLTransformerErrorHandlingErrorInvalidInput);
	expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to.equal(@"totallyNotAnNSURL");
});

it(@"should parse a different model class", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beKindOf(MTLTestModel.class);
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	__block NSError *serializationError;
	expect([MTLJSONAdapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(values);
	expect(serializationError).to.beNil();
});

it(@"should serialize different model classes", ^{
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModelClass:MTLClassClusterModel.class];

	MTLChocolateClassClusterModel *chocolate = [MTLChocolateClassClusterModel modelWithDictionary:@{
		@"bitterness": @100
	} error:NULL];

	NSError *error = nil;
	NSDictionary *chocolateValues = [adapter JSONDictionaryFromModel:chocolate error:&error];

	expect(error).to.beNil();
	expect(chocolateValues).to.equal((@{
		@"flavor": @"chocolate",
		@"chocolate_bitterness": @"100"
	}));

	MTLStrawberryClassClusterModel *strawberry = [MTLStrawberryClassClusterModel modelWithDictionary:@{
		@"freshness": @20
	} error:NULL];

	NSDictionary *strawberryValues = [adapter JSONDictionaryFromModel:strawberry error:&error];

	expect(error).to.beNil();
	expect(strawberryValues).to.equal((@{
		@"flavor": @"strawberry",
		@"strawberry_freshness": @20
	}));
});

it(@"should parse model classes not inheriting from MTLModel", ^{
	NSDictionary *values = @{
		@"name": @"foo",
	};

	NSError *error = nil;
	MTLConformingModel *model = [MTLJSONAdapter modelOfClass:MTLConformingModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beKindOf(MTLConformingModel.class);
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
});

it(@"should return an error when no suitable model class is found", ^{
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:@{} error:&error];
	expect(model).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
});

it(@"should validate models", ^{
	NSError *error = nil;
	MTLValidationModel *model = [MTLJSONAdapter modelOfClass:MTLValidationModel.class fromJSONDictionary:@{} error:&error];

	expect(model).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameMissing);
});

describe(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
		@"username": @"foo"
	};

	NSDictionary *value2 = @{
		@"username": @"bar"
	};

	NSArray *JSONModels = @[ value1, value2 ];

	it(@"should initialize models from an array of JSON dictionaries", ^{
		NSError *error = nil;
		NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];

		expect(error).to.beNil();
		expect(mantleModels).toNot.beNil();
		expect(mantleModels).haveCountOf(2);
		expect([mantleModels[0] name]).to.equal(@"foo");
		expect([mantleModels[1] name]).to.equal(@"bar");
	});

	it(@"should not be affected by a NULL error parameter", ^{
		NSError *error = nil;
		NSArray *expected = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];
		NSArray *models = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:NULL];

		expect(models).to.equal(expected);
	});
});

it(@"should return nil and an error if it fails to initialize any model from an array", ^{
	NSDictionary *value1 = @{
		@"username": @"foo",
		@"count": @"1",
	};

	NSDictionary *value2 = @{
		@"count": @[ @"This won't parse" ],
	};

	NSArray *JSONModels = @[ value1, value2 ];

	NSError *error = nil;
	NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLSubstitutingTestModel.class fromJSONArray:JSONModels error:&error];

	expect(error).toNot.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
	expect(mantleModels).to.beNil();
});

it(@"should return an array of dictionaries from models", ^{
	MTLTestModel *model1 = [[MTLTestModel alloc] init];
	model1.name = @"foo";

	MTLTestModel *model2 = [[MTLTestModel alloc] init];
	model2.name = @"bar";

	NSError *error;
	NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:@[ model1, model2 ] error:&error];

	expect(error).to.beNil();

	expect(JSONArray).toNot.beNil();
	expect(JSONArray).haveCountOf(2);
	expect(JSONArray[0][@"username"]).to.equal(@"foo");
	expect(JSONArray[1][@"username"]).to.equal(@"bar");
});

SpecEnd
