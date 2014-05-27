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

__block NSPersistentStoreCoordinator *persistentStoreCoordinator;

beforeEach(^{
	NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"MTLManagedObjectTest" withExtension:@"momd"];
	expect(url).notTo.beNil();

	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
	expect(model).notTo.beNil();

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	expect(persistentStoreCoordinator).notTo.beNil();
	expect([persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL]).notTo.beNil();
});

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

SpecEnd
