//
//  MTLManagedObjectAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-17.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataObjects.h"

#import "MTLCoreDataTestModels.h"

SpecBegin(MTLManagedObjectAdapter)

__block NSPersistentStoreCoordinator *persistentStoreCoordinator;

beforeEach(^{
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
	expect(model).notTo.beNil();

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	expect(persistentStoreCoordinator).notTo.beNil();
	expect([persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL]).notTo.beNil();
});

describe(@"with a confined context", ^{
	__block NSManagedObjectContext *context;

	__block NSEntityDescription *parentEntity;
	__block NSEntityDescription *childEntity;

	beforeEach(^{
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		expect(context).notTo.beNil();

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;

		parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
		expect(parentEntity).notTo.beNil();

		childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:context];
		expect(childEntity).notTo.beNil();
	});

	describe(@"+modelOfClass:fromManagedObject:error:", ^{
		__block MTLParent *parent;

		__block NSDate *date;
		__block NSString *numberString;
		__block NSString *requiredString;
		__block NSURL *URL;

		beforeEach(^{
			date = [NSDate date];
			numberString = @"123";
			requiredString = @"foobar";
			URL = [NSURL URLWithString:@"http://github.com"];

			parent = [MTLParent insertInManagedObjectContext:context];
			expect(parent).notTo.beNil();

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChild *child = [MTLChild insertInManagedObjectContext:context];
				expect(child).notTo.beNil();

				child.childID = @(i);
				[parent addOrderedChildrenObject:child];
			}

			for (NSUInteger i = 3; i < 6; i++) {
				MTLChild *child = [MTLChild insertInManagedObjectContext:context];
				expect(child).notTo.beNil();

				child.childID = @(i);
				[parent addUnorderedChildrenObject:child];
			}

			parent.string = requiredString;

			__block NSError *error = nil;
			expect([context save:&error]).to.beTruthy();
			expect(error).to.beNil();

			// Make sure that pending changes are picked up too.
			[parent setValue:@(numberString.integerValue) forKey:@"number"];
			[parent setValue:date forKey:@"date"];
			[parent setValue:URL.absoluteString forKey:@"url"];
		});

		it(@"should initialize a MTLParentTestModel with children", ^{
			NSError *error = nil;
			MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
			expect(parentModel).to.beKindOf(MTLParentTestModel.class);
			expect(error).to.beNil();

			expect(parentModel.date).to.equal(date);
			expect(parentModel.numberString).to.equal(numberString);
			expect(parentModel.requiredString).to.equal(requiredString);
			expect(parentModel.URL).to.equal(URL);

			expect(parentModel.orderedChildren).to.haveCountOf(3);
			expect(parentModel.unorderedChildren).to.haveCountOf(3);

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

	describe(@"+managedObjectFromModel:insertingIntoContext:error:", ^{
		__block MTLParentTestModel *parentModel;

		beforeEach(^{
			parentModel = [MTLParentTestModel modelWithDictionary:@{
				@"date": [NSDate date],
				@"numberString": @"1234",
				@"requiredString": @"foobar"
			} error:NULL];
			expect(parentModel).notTo.beNil();

			NSMutableArray *orderedChildren = [NSMutableArray array];
			NSMutableSet *unorderedChildren = [NSMutableSet set];

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
					@"childID": @(i),
					@"parent2": parentModel
				} error:NULL];
				expect(child).notTo.beNil();

				[orderedChildren addObject:child];
			}

			for (NSUInteger i = 3; i < 6; i++) {
				MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
					@"childID": @(i),
					@"parent1": parentModel
				} error:NULL];
				expect(child).notTo.beNil();

				[unorderedChildren addObject:child];
			}

			parentModel.orderedChildren = orderedChildren;
			parentModel.unorderedChildren = unorderedChildren;
		});

		it(@"should insert a managed object with children", ^{
			__block NSError *error = nil;
			MTLParent *parent = (MTLParent *)[MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
			expect(parent).notTo.beNil();
			expect(parent).to.beKindOf(MTLParent.class);
			expect(error).to.beNil();

			expect(parent.entity).to.equal(parentEntity);
			expect(context.insertedObjects).to.contain(parent);

			expect(parent.date).to.equal(parentModel.date);
			expect(parent.number.stringValue).to.equal(parentModel.numberString);
			expect(parent.string).to.equal(parentModel.requiredString);

			expect(parent.orderedChildren).to.haveCountOf(3);

			expect(parent.unorderedChildren).to.haveCountOf(3);

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChild *child = parent.orderedChildren[i];
				expect(child).to.beKindOf(MTLChild.class);

				expect(child.entity).to.equal(childEntity);
				expect(context.insertedObjects).to.contain(child);

				expect(child.childID).to.equal(i);
				expect(child.parent1).to.beNil();
				expect(child.parent2).to.equal(parent);
			}

			for (MTLChild *child in parent.unorderedChildren) {
				expect(child).to.beKindOf(MTLChild.class);

				expect(child.entity).to.equal(childEntity);
				expect(context.insertedObjects).to.contain(child);

				expect(child.childID).to.beGreaterThanOrEqualTo(3);
				expect(child.childID).to.beLessThan(6);

				expect(child.parent1).to.equal(parent);
				expect(child.parent2).to.beNil();
			}

			expect([context save:&error]).to.beTruthy();
			expect(error).to.beNil();
		});

		it(@"should respect the uniqueness constraint", ^{
			NSError *errorOne;
			MTLParent *parentOne = (MTLParent *)[MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorOne];
			expect(parentOne).notTo.beNil();
			expect(errorOne).to.beNil();

			NSError *errorTwo;
			MTLParent *parentTwo = (MTLParent *)[MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorTwo];
			expect(parentTwo).notTo.beNil();
			expect(errorTwo).to.beNil();

			expect(parentOne.objectID).to.equal(parentTwo.objectID);
		});
	});
});

describe(@"with a main queue context", ^{
	__block NSManagedObjectContext *context;

	beforeEach(^{
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		expect(context).notTo.beNil();

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;
	});

	it(@"should not deadlock on the main thread", ^{
		MTLParent *parent = [MTLParent insertInManagedObjectContext:context];
		expect(parent).notTo.beNil();

		parent.string = @"foobar";

		NSError *error = nil;
		MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
		expect(parentModel).to.beKindOf(MTLParentTestModel.class);
		expect(error).to.beNil();
	});
});

SpecEnd
