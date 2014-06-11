//
//  MTLJSONAdapterManagedObjectSpec.m
//  Mantle
//
//  Created by Christian Bianciotto on 2014-06-10.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestManagedObjectModel.h"

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

it(@"should initialize from a model and JSON on update", ^{
	NSDictionary *values = @{
							 @"username": NSNull.null,
							 @"count": @"5",
							 };
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												} error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values model:model error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
									 @"username": NSNull.null,
									 @"count": @"5",
									 @"nested": @{ @"name": NSNull.null },
									 };
	
	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize from a model", ^{
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												} error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();

	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModel:model];
	expect(adapter).notTo.beNil();
	expect(adapter.model).to.beIdenticalTo(model);

	NSDictionary *JSONDictionary = @{
		@"username": @"foobar",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize nested key paths from JSON", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};
	
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];

	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values model:model error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(values);
});

it(@"should return NO and error with an invalid key path from JSON on update",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};

	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values model:model error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return NO and error with an illegal JSON mapping on update", ^{
	NSDictionary *values = @{
							 @"username": @"foo"
							 };
	MTLIllegalJSONMappingManagedObjectModel *model = [MTLIllegalJSONMappingManagedObjectModel insertInManagedObjectContext:context];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONMapping);
});

it(@"should support key paths across arrays on update", ^{
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
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"names": @[
														@"foobar"
														]
												} error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.names).to.equal((@[ @"foo", @"bar", @"baz" ]));
});

it(@"should update without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
							 @"username": @"foo",
							 @"nested": NSNull.null,
							 @"count": @"0"
							 };
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												}  error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.beNil();
});

it(@"should return NO and an error with a nil JSON dictionary on update", ^{
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												}  error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:nil error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return NO and an error with a wrong data type as dictionary on update", ^{
	id wrongDictionary = @"";
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												}  error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:wrongDictionary error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should ignore unrecognized JSON keys on update", ^{
	NSDictionary *values = @{
							 @"foobar": @"foo",
							 @"count": @"2",
							 @"_": NSNull.null,
							 @"username": @"buzz",
							 @"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
							 };
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												}  error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to update if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
							 @"username": @"this is too long a name",
							 };
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError = nil;
	BOOL update = [model updateWithDictionary:@{
												@"name": @"foobar",
												@"count": @5,
												}  error:&updateError];
	expect(update).notTo.beFalsy();
	expect(updateError).to.beNil();
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestManagedObjectModelErrorDomain);
	expect(error.code).to.equal(MTLTestManagedObjectModelNameTooLong);
});

it(@"should return an error when suitable model class is found on update", ^{
	MTLSubstitutingTestManagedObjectModel *model = [MTLSubstitutingTestManagedObjectModel insertInManagedObjectContext:context];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:@{} error:&error];
	expect(updated).beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorClassFoundOnUpdate);
});

it(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo"
							 };
	
	NSDictionary *value2 = @{
							 @"username": @"bar"
							 };
	MTLTestManagedObjectModel *model1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError1 = nil;
	BOOL update1 = [model1 updateWithDictionary:@{
												@"name": @"foobar"
												}  error:&updateError1];
	expect(update1).notTo.beFalsy();
	expect(updateError1).to.beNil();
	
	MTLTestManagedObjectModel *model2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError2 = nil;
	BOOL update2 = [model2 updateWithDictionary:@{
												@"name": @"foobar"
												}  error:&updateError2];
	expect(update2).notTo.beFalsy();
	expect(updateError2).to.beNil();
	
	
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
});

it(@"should return NO and an error if it fails to update any models from an array", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo",
							 @"count": @"1",
							 };
	MTLTestManagedObjectModel *model1 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError1 = nil;
	BOOL update1 = [model1 updateWithDictionary:@{
												  @"name": @"foobar"
												  }  error:&updateError1];
	expect(update1).notTo.beFalsy();
	expect(updateError1).to.beNil();
	
	MTLTestManagedObjectModel *model2 = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	NSError *updateError2 = nil;
	BOOL update2 = [model2 updateWithDictionary:@{
												  @"name": @"foobar"
												  }  error:&updateError2];
	expect(update2).notTo.beFalsy();
	expect(updateError2).to.beNil();
	
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
