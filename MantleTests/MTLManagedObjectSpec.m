//
//  MTLManagedObjectSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 17/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLManagedObject.h"

#import "MTLManagedObjectSubclasses.h"

SpecBegin(MTLManagedObject)

it(@"should include properties from the entity that aren't exposed as properties", ^{
	NSSet *expectedKeys = [NSSet setWithObjects:@"date", @"string", @"number", @"url", nil];

	expect(MTLManagedObjectParent.propertyKeys).to.equal(expectedKeys);
});

describe(@"when initialized with a dictionary", ^{
	__block NSDictionary *values;
	__block MTLManagedObjectParent *model;

	beforeEach(^{
		NSError *error;

		values = @{
			@"date": [NSDate dateWithTimeIntervalSince1970:0],
			@"number": @5,
			@"string": @"fuzzbuzz",
			@"url": NSNull.null,
		};

		model = [MTLManagedObjectParent modelWithDictionary:values error:&error];

		expect(error).to.beNil();
		expect(model).notTo.beNil();
	});

	it(@"should initialize with the given values", ^{
		expect(model.date).to.equal([NSDate dateWithTimeIntervalSince1970:0]);
		expect(model.number).to.equal(5);
		expect(model.string).to.equal(@"fuzzbuzz");
		expect(model.url).to.equal(nil);

		expect(model.dictionaryValue).to.equal(values);
		expect([model dictionaryWithValuesForKeys:values.allKeys]).to.equal(values);
	});

	it(@"should not have a context", ^{
		expect(model.managedObjectContext).to.beNil();
	});
});

describe(@"Persisting a model", ^{
	__block NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__block NSManagedObjectContext *context;
	__block NSEntityDescription *entity;

	__block MTLManagedObjectParent *parent;

	beforeEach(^{
		// It's necessary to use the exact same instance for the MOM.
		// Loading it again from disk using -initWithContentsOfURL: will cause
		// -[NSManagedObjectContext save:] to fail, even though the two models
		// are considered equal.
		//
		// Is that expected behavior or a bug in CoreData?
		NSManagedObjectModel *model = MTLManagedObjectParent.managedObjectModel;

		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

		expect(persistentStoreCoordinator).notTo.beNil();
		expect(persistentStoreCoordinator.managedObjectModel).to.equal(model);
		expect(persistentStoreCoordinator.managedObjectModel).to.equal(MTLManagedObjectParent.managedObjectModel);

		NSPersistentStore *store = [persistentStoreCoordinator
			addPersistentStoreWithType:NSInMemoryStoreType
			configuration:nil
			URL:nil
			options:nil
			error:NULL];

		expect(store).notTo.beNil();

		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		expect(context).notTo.beNil();

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;

		entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
		expect(entity).notTo.beNil();

		parent = [MTLManagedObjectParent modelWithDictionary:@{
			@"date": [NSDate dateWithTimeIntervalSince1970:0],
			@"number": @5,
			@"string": @"fuzzbuzz",
			@"url": NSNull.null,
		} error:NULL];
		expect(parent.entity).to.equal(entity);

		[context insertObject:parent];

		NSError *error;
		[context save:&error];

		expect(error).to.beNil();
	});

	it(@"should give it a context", ^{
		expect(parent.managedObjectContext).to.equal(context);
	});

	it(@"should allow it to be fetched", ^{
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Parent"];
		request.predicate = [NSPredicate predicateWithFormat:@"string == 'fuzzbuzz'"];

		NSError *error;
		id result = [context executeFetchRequest:request error:&error].lastObject;

		expect(error).to.beNil();

		expect(result).notTo.beNil();
		expect(result).to.equal(parent);
	});
});

SpecEnd
