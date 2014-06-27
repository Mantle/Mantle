//
//  MTLJSONAdapterUpdateSpec.m
//  Mantle
//
//  Created by Christian Bianciotto on 2014-05-09.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"
#import "MTLTestJSONAdapter.h"


SpecBegin(MTLJSONAdapterUpdate)

it(@"should update nested key paths from JSON", ^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": @{ @"name": @"bar" },
							 @"count": @"0"
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");
	
	__block NSError *serializationError;
	expect([MTLJSONAdapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(values);
	expect(serializationError).to.beNil();
});

it(@"it should update properties with multiple key paths from JSON", ^{
	NSDictionary *values = @{
							 @"location": @20,
							 @"length": @12,
							 @"nested": @{
									 @"location": @12,
									 @"length": @34
									 }
							 };
	MTLMultiKeypathModel *model = [MTLMultiKeypathModel modelWithDictionary:@{} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(error).to.beNil();
	
	expect(model.range.location).to.equal(20);
	expect(model.range.length).to.equal(12);
	
	expect(model.nestedRange.location).to.equal(12);
	expect(model.nestedRange.length).to.equal(34);
	
	__block NSError *serializationError;
	expect([MTLJSONAdapter JSONDictionaryFromModel:model error:&serializationError]).to.equal(values);
	expect(serializationError).to.beNil();
});

it(@"should return NO and error with an invalid key path from JSON",^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": @"bar",
							 @"count": @"0"
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
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
	MTLArrayTestModel *model = [MTLArrayTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should update without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": NSNull.null,
							 @"count": @"0"
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
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
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to update if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
							 @"username": @"this is too long a name",
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameTooLong);
});

it(@"should fail to update if JSON transformer fails", ^{
	NSDictionary *values = @{
							 @"URL": @666,
							 };
	MTLURLModel *model = [MTLURLModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTransformerErrorHandlingErrorDomain);
	expect(error.code).to.equal(MTLTransformerErrorHandlingErrorInvalidInput);
	expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to.equal(@666);
});

it(@"should fail to deserialize if the JSON types don't match the properties", ^{
	NSDictionary *values = @{
							 @"flag": @"Potentially"
							 };
	MTLBoolModel *model = [MTLBoolModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
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
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	MTLTestJSONAdapter *adapter = [[MTLTestJSONAdapter alloc] initWithModelClass:MTLTestModel.class];
	
	NSError *error = nil;
	BOOL updated = [MTLTestJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
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
	MTLIDModel *model = [MTLIDModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(error).to.beNil();
	expect(model.anyObject).to.equal(@"Not an NSValue");
	
	expect(error.domain).to.beNil();
});

it(@"should return an error when suitable model class is found", ^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": @{ @"name": @"bar" },
							 @"count": @"0"
							 };
	MTLSubstitutingTestModel *model = [MTLSubstitutingTestModel modelWithDictionary:@{} error:NULL];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorClassFoundOnUpdate);
});

it(@"should parse model classes not inheriting from MTLModel", ^{
	NSDictionary *values = @{
							 @"name": @"foo",
							 };
	MTLConformingModel *model = [[MTLConformingModel alloc] init];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"foo");
});

describe(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo"
							 };
	
	NSDictionary *value2 = @{
							 @"username": @"bar"
							 };
	MTLTestModel *model1 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	MTLTestModel *model2 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	
	NSArray *JSONModels = @[ value1, value2 ];
	NSArray *models = @[ model1, model2 ];
	
	it(@"should update models from an array of JSON dictionaries", ^{
		NSError *error = nil;
		BOOL updated = [MTLJSONAdapter upadeModels:models fromJSONArray:JSONModels error:&error];
		expect(updated).notTo.beFalsy();
		
		expect(error).to.beNil();
		expect([models[0] name]).to.equal(@"foo");
		expect([models[1] name]).to.equal(@"bar");
	});
	
	it(@"should not be affected by a NULL error parameter", ^{
		NSError *error = nil;
		NSArray *expected = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];
		
		expect(models).to.equal(expected);
	});
});

it(@"should return NO and an error if it fails to update any models from an array", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo",
							 @"count": @"1",
							 };
	MTLTestModel *model1 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	MTLTestModel *model2 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	
	NSArray *JSONModels = @[ value1 ];
	NSArray *models = @[ model1, model2 ];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter upadeModels:models fromJSONArray:JSONModels error:&error];
	expect(updated).beFalsy();
	
	expect(error).toNot.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

SpecEnd
