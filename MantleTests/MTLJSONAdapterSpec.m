//
//  MTLJSONAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLJSONAdapter)

it(@"should initialize from JSON", ^{
	NSDictionary *values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};

	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values modelClass:MTLTestModel.class error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();

	MTLTestModel *model = (id)adapter.model;
	expect(model).notTo.beNil();
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	__block NSError *serializationError;
	expect([adapter serializeToJSONDictionary:&serializationError]).to.equal(JSONDictionary);
	expect(serializationError).to.beNil();
});

it(@"should initialize from a model", ^{
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];

	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModel:model];
	expect(adapter).notTo.beNil();
	expect(adapter.model).to.beIdenticalTo(model);

	NSDictionary *JSONDictionary = @{
		@"username": @"foobar",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	__block NSError *serializationError;
	expect([adapter serializeToJSONDictionary:&serializationError]).to.equal(JSONDictionary);
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

it(@"should return nil and an error with a nil JSON dictionary", ^{
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:nil modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return nil and an error with a wrong data type as dictionary", ^{
	NSError *error = nil;
	id wrongDictionary = @"";
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:wrongDictionary modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
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

it(@"should return an error when no suitable model class is found", ^{
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:@{} error:&error];
	expect(model).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
});

SpecEnd
