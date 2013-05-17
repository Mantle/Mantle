//
//  MTLManagedObjectAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-17.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataTestModels.h"

SpecBegin(MTLManagedObjectAdapter)

__block NSPersistentStoreCoordinator *persistentStoreCoordinator;
__block NSManagedObjectContext *context;

__block NSEntityDescription *parentEntity;
__block NSEntityDescription *childEntity;

beforeEach(^{
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
	expect(model).notTo.beNil();

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	expect(persistentStoreCoordinator).notTo.beNil();
	expect([persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL]).notTo.beNil();

	context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	expect(context).notTo.beNil();

	context.persistentStoreCoordinator = persistentStoreCoordinator;

	parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
	expect(parentEntity).notTo.beNil();

	childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:context];
	expect(childEntity).notTo.beNil();
});

describe(@"+modelOfClass:fromManagedObject:error:", ^{
	__block NSManagedObject *parent;

	__block NSDate *date;
	__block NSString *numberString;
	__block NSString *requiredString;

	beforeEach(^{
		date = [NSDate date];
		numberString = @"1234";
		requiredString = @"foobar";

		parent = [[NSManagedObject alloc] initWithEntity:parentEntity insertIntoManagedObjectContext:context];
		expect(parent).notTo.beNil();

		[parent setValue:date forKey:@"date"];
		[parent setValue:@(numberString.integerValue) forKey:@"number"];
		[parent setValue:requiredString forKey:@"string"];

		for (NSUInteger i = 0; i < 3; i++) {
			NSManagedObject *child = [[NSManagedObject alloc] initWithEntity:childEntity insertIntoManagedObjectContext:context];
			expect(child).notTo.beNil();

			[child setValue:@(i) forKey:@"id"];
			[[parent mutableOrderedSetValueForKey:@"orderedChildren"] addObject:child];
		}

		for (NSUInteger i = 3; i < 6; i++) {
			NSManagedObject *child = [[NSManagedObject alloc] initWithEntity:childEntity insertIntoManagedObjectContext:context];
			expect(child).notTo.beNil();

			[child setValue:@(i) forKey:@"id"];
			[[parent mutableSetValueForKey:@"unorderedChildren"] addObject:child];
		}

		expect([context save:NULL]).to.beTruthy();
	});

	it(@"should initialize a MTLParentTestModel with children", ^{
		NSError *error = nil;
		MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
		expect(parentModel).to.beKindOf(MTLParentTestModel.class);
		expect(error).to.beNil();

		expect(parentModel.date).to.equal(date);
		expect(parentModel.numberString).to.equal(numberString);
		expect(parentModel.requiredString).to.equal(requiredString);

		expect(parentModel.orderedChildren.count).to.equal(3);
		expect(parentModel.unorderedChildren.count).to.equal(3);

		for (NSUInteger i = 0; i < 3; i++) {
			MTLChildTestModel *child = parentModel.orderedChildren[i];
			expect(child).to.beKindOf(MTLChildTestModel.class);

			expect(child.childID).to.equal(i);
			expect(child.parent1).to.beNil();
			expect(child.parent2).to.beIdenticalTo(parentModel);
		}

		for (MTLChildTestModel *child in parentModel.unorderedChildren) {
			expect(child).to.beKindOf(MTLChildTestModel.class);

			expect(child.childID).to.beGreaterThanOrEqualTo(3);
			expect(child.childID).to.beLessThan(6);

			expect(child.parent1).to.beIdenticalTo(parentModel);
			expect(child.parent2).to.beNil();
		}
	});
});

SpecEnd
