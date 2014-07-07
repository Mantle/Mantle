//
//  MTLManagedObjectModelSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestManagedObjectModel.h"

SpecBegin(MTLManagedObjectModel)

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

it(@"should not loop infinitely in +propertyKeys without any properties", ^{
	expect(MTLEmptyTestManagedObjectModel.propertyKeys).to.equal([NSSet set]);
});

it(@"should not include dynamic readonly properties in +propertyKeys", ^{
	NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", @"weakModel", nil];
	expect(MTLTestManagedObjectModel.propertyKeys).to.equal(expectedKeys);
});

it(@"should not update with a nil dictionary", ^{
	NSError *error = nil;
	MTLTestManagedObjectModel *dictionaryModel = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	BOOL upadte = [dictionaryModel updateWithDictionary:nil error:&error];
	expect(upadte).notTo.beFalsy();
	expect(error).to.beNil();
	
	MTLTestManagedObjectModel *defaultModel = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	expect(dictionaryModel.dictionaryValue).to.equal(defaultModel.dictionaryValue);
});

describe(@"update with a dictionary of values", ^{
	__block MTLEmptyTestManagedObjectModel *emptyModel;
	__block NSDictionary *values;
	__block MTLTestManagedObjectModel *model;
	
	beforeEach(^{
		emptyModel = [MTLEmptyTestManagedObjectModel insertInManagedObjectContext:context];
		expect(emptyModel).notTo.beNil();
		
		values = @{
				   @"name": @"foobar",
				   @"count": @(5),
				   @"nestedName": @"fuzzbuzz",
				   @"weakModel": emptyModel,
				   };
		
		NSError *error = nil;
		model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		BOOL update = [model updateWithDictionary:values error:&error];
		expect(update).notTo.beFalsy();
		expect(error).to.beNil();
	});
	
	it(@"should initialize with the given values", ^{
		expect(model.name).to.equal(@"foobar");
		expect(model.count).to.equal(5);
		expect(model.nestedName).to.equal(@"fuzzbuzz");
		expect(model.weakModel).to.equal(emptyModel);
		
		expect(model.dictionaryValue).to.equal(values);
		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});
	
	it(@"should compare equal to a matching model (dictionaryValue only)", ^{
		expect(model).to.equal(model);
		
		MTLTestManagedObjectModel *matchingModel = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		NSError *error = nil;
		BOOL update = [matchingModel updateWithDictionary:values error:&error];
		expect(update).notTo.beFalsy();
		expect(error).to.beNil();
		expect(model).notTo.to.equal(matchingModel);
		expect(model.hash).notTo.to.equal(matchingModel.hash);
		expect(model.dictionaryValue).to.equal(matchingModel.dictionaryValue);
	});
	
	it(@"should not compare equal to different model", ^{
		MTLTestManagedObjectModel *differentModel = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		expect(model).notTo.equal(differentModel);
		expect(model.dictionaryValue).notTo.equal(differentModel.dictionaryValue);
	});
});

it(@"should fail to update if dictionary validation fails", ^{
	NSError *error = nil;
	MTLTestManagedObjectModel *model = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	BOOL upadte = [model updateWithDictionary:@{ @"name": @"this is too long a name" } error:&error];
	expect(upadte).to.beFalsy();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestManagedObjectModelErrorDomain);
	expect(error.code).to.equal(MTLTestManagedObjectModelNameTooLong);
});

it(@"should merge two models together", ^{
	MTLTestManagedObjectModel *target = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	[target updateWithDictionary:@{ @"name": @"foo", @"count": @(5) } error:NULL];
	expect(target).notTo.beNil();

	MTLTestManagedObjectModel *source = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
	[source updateWithDictionary:@{ @"name": @"bar", @"count": @(3) } error:NULL];
	expect(source).notTo.beNil();

	[target mergeValuesForKeysFromModel:source];

	expect(target.name).to.equal(@"bar");
	expect(target.count).to.equal(8);
});

describe(@"merging with model subclasses", ^{
	__block MTLTestManagedObjectModel *superclass;
	__block MTLSubclassTestManagedObjectModel *subclass;

	beforeEach(^{
		superclass = [MTLTestManagedObjectModel insertInManagedObjectContext:context];
		BOOL upadteSuperclass = [superclass updateWithDictionary:@{
													@"name": @"foo",
													@"count": @5
													} error:nil];
		expect(upadteSuperclass).notTo.beFalsy();
		expect(superclass).notTo.beNil();

		subclass = [MTLSubclassTestManagedObjectModel insertInManagedObjectContext:context];
		BOOL updateSubclass = [subclass updateWithDictionary:@{
													@"name": @"bar",
													@"count": @3,
													@"generation": @1,
													@"role": @"subclass"
													} error:nil];
		expect(updateSubclass).notTo.beFalsy();
		expect(subclass).notTo.beNil();
	});

	it(@"should merge from subclass model", ^{
		[superclass mergeValuesForKeysFromModel:subclass];

		expect(superclass.name).to.equal(@"bar");
		expect(superclass.count).to.equal(8);
	});

	it(@"should merge from superclass model", ^{
		[subclass mergeValuesForKeysFromModel:superclass];

		expect(subclass.name).to.equal(@"foo");
		expect(subclass.count).to.equal(8);
		expect(subclass.generation).to.equal(1);
		expect(subclass.role).to.equal(@"subclass");
	});
});

SpecEnd
