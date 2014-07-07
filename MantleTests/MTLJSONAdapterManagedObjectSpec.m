//
//  MTLJSONAdapterManagedObjectSpec.m
//  Mantle
//
//  Created by Christian Bianciotto on 2014-06-10.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestManagedObjectModel.h"
#import "MTLTestModel.h"
#import "MTLTestJSONAdapter.h"

SpecBegin(MTLJSONAdapterManagedObject)

__block NSPersistentStoreCoordinator *persistentStoreCoordinator;
__block NSManagedObjectContext *context;

beforeEach(^{
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
	expect(model).notTo.beNil();
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	expect(persistentStoreCoordinator).notTo.beNil();
	expect([persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL]).notTo.beNil();
	
	context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	expect(context).notTo.beNil();
	
	context.undoManager = nil;
	context.persistentStoreCoordinator = persistentStoreCoordinator;
});

it(@"should update nested key paths from JSON", ^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": @{ @"name": @"bar" },
							 @"count": @"0"
							 };
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
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
	MTLMultiKeypathManagedObjectModel *model = [MTLMultiKeypathManagedObjectModel insertInManagedObjectContext:context];
	
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
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
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
	MTLArrayTestManagedObjectModel *model = [MTLArrayTestManagedObjectModel insertInManagedObjectContext:context];
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
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
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
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
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
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestManagedObjectModelErrorDomain);
	expect(error.code).to.equal(MTLTestManagedObjectModelNameTooLong);
});

it(@"should implicitly transform URLs", ^{
	MTLURLManagedObjectModel *model = [MTLURLManagedObjectModel insertInManagedObjectContext:context];
	model.URL=[NSURL URLWithString:@"http://github.com"];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
	
	expect(JSONDictionary[@"URL"]).to.equal(@"http://github.com");
	expect(error).to.beNil();
});

it(@"should implicitly transform BOOLs", ^{
	MTLBoolManagedObjectModel *model = [MTLBoolManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
	
	expect(JSONDictionary[@"flag"]).to.beIdenticalTo((id)kCFBooleanFalse);
	expect(error).to.beNil();
});

it(@"should not invoke implicit transformers for property keys not actually backed by properties", ^{
	MTLNonPropertyManagedObjectModel *model = [MTLNonPropertyManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
	
	expect(error).to.beNil();
	expect(JSONDictionary[@"homepage"]).to.equal(model.homepage);
});

it(@"should fail to update if JSON transformer fails", ^{
	NSDictionary *values = @{
							 @"URL": @666,
							 };
	MTLURLManagedObjectModel *model = [MTLURLManagedObjectModel insertInManagedObjectContext:context];
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
	MTLBoolManagedObjectModel *model = [MTLBoolManagedObjectModel insertInManagedObjectContext:context];
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
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	MTLTestJSONAdapter *adapter = [[MTLTestJSONAdapter alloc] initWithModelClass:MTLTestManagedObjectModel.class];
	
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
	MTLIDManagedObjectModel *model = [MTLIDManagedObjectModel insertInManagedObjectContext:context];
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
	MTLSubstitutingTestManagedObjectModel *model = [MTLSubstitutingTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorClassFoundOnUpdate);
});

it(@"should validate models", ^{
	MTLValidationManagedObjectModel *model = [MTLValidationManagedObjectModel insertInManagedObjectContext:context];
	expect(model).notTo.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:@{} error:&error];
	expect(updated).to.beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestManagedObjectModelErrorDomain);
	expect(error.code).to.equal(MTLTestManagedObjectModelNameMissing);
});

it(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo"
							 };
	
	NSDictionary *value2 = @{
							 @"username": @"bar"
							 };
	MTLTestManagedObjectModel *model1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model1).notTo.beNil();
	MTLTestManagedObjectModel *model2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model2).notTo.beNil();
	
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
		
		MTLTestManagedObjectModel *expected1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		expect(expected1).notTo.beNil();
		MTLTestManagedObjectModel *expected2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		expect(expected2).notTo.beNil();
		
		NSArray *expected = @[ expected1, expected2 ];
		
		BOOL updated = [MTLJSONAdapter upadeModels:expected fromJSONArray:JSONModels error:&error];
		expect(updated).notTo.beFalsy();
		
		expect(models).to.equal(expected);
	});
});

it(@"should return NO and an error if it fails to update any models from an array", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo",
							 @"count": @"1",
							 };
	MTLTestManagedObjectModel *model1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model1).notTo.beNil();
	MTLTestManagedObjectModel *model2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(model2).notTo.beNil();
	
	NSArray *JSONModels = @[ value1 ];
	NSArray *models = @[ model1, model2 ];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter upadeModels:models fromJSONArray:JSONModels error:&error];
	expect(updated).beFalsy();
	
	expect(error).toNot.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return an array of dictionaries from models", ^{
	MTLTestManagedObjectModel *model1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	model1.name = @"foo";
	
	MTLTestManagedObjectModel *model2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
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
