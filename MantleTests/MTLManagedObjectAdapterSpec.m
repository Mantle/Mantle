//
//  MTLManagedObjectAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-17.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

#import "MTLCoreDataObjects.h"

#import "MTLCoreDataTestModels.h"

QuickSpecBegin(MTLManagedObjectAdapterSpec)

__block NSPersistentStoreCoordinator *persistentStoreCoordinator;

beforeEach(^{
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
	expect(model).notTo(beNil());

	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	expect(persistentStoreCoordinator).notTo(beNil());
	expect([persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL]).notTo(beNil());
});

describe(@"with a confined context", ^{
	__block NSManagedObjectContext *context;

	__block NSEntityDescription *parentEntity;
	__block NSEntityDescription *childEntity;

	beforeEach(^{
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		expect(context).notTo(beNil());

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;

		parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
		expect(parentEntity).notTo(beNil());

		childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:context];
		expect(childEntity).notTo(beNil());
	});

	describe(@"+modelOfClass:fromManagedObject:error:", ^{
		__block MTLParent *parent;

		__block NSDate *date;
		__block NSString *numberString;
		__block NSString *requiredString;

		beforeEach(^{
			date = [NSDate date];
			numberString = @"123";
			requiredString = @"foobar";

			parent = [MTLParent insertInManagedObjectContext:context];
			expect(parent).notTo(beNil());

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChild *child = [MTLChild insertInManagedObjectContext:context];
				expect(child).notTo(beNil());

				child.childID = @(i);
				[parent addOrderedChildrenObject:child];
			}

			for (NSUInteger i = 3; i < 6; i++) {
				MTLChild *child = [MTLChild insertInManagedObjectContext:context];
				expect(child).notTo(beNil());

				child.childID = @(i);
				[parent addUnorderedChildrenObject:child];
			}

			parent.string = requiredString;

			__block NSError *error = nil;
			expect(@([context save:&error])).to(beTruthy());
			expect(error).to(beNil());

			// Make sure that pending changes are picked up too.
			[parent setValue:@(numberString.integerValue) forKey:@"number"];
			[parent setValue:date forKey:@"date"];
		});

		it(@"should initialize a MTLParentTestModel with children", ^{
			NSError *error = nil;
			MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
			expect(parentModel).to(beAnInstanceOf(MTLParentTestModel.class));
			expect(error).to(beNil());

			expect(parentModel.date).to(equal(date));
			expect(parentModel.numberString).to(equal(numberString));
			expect(parentModel.requiredString).to(equal(requiredString));

			expect(@(parentModel.orderedChildren.count)).to(equal(@3));
			expect(@(parentModel.unorderedChildren.count)).to(equal(@3));

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChildTestModel *child = parentModel.orderedChildren[i];
				expect(child).to(beAnInstanceOf(MTLChildTestModel.class));

				expect(@(child.childID)).to(equal(@(i)));
				expect(child.parent1).to(beNil());
				expect(child.parent2).to(beIdenticalTo(parentModel));
			}

			for (MTLChildTestModel *child in parentModel.unorderedChildren) {
				expect(child).to(beAnInstanceOf(MTLChildTestModel.class));

				expect(@(child.childID)).to(beGreaterThanOrEqualTo(@3));
				expect(@(child.childID)).to(beLessThan(@6));

				expect(child.parent1).to(beIdenticalTo(parentModel));
				expect(child.parent2).to(beNil());
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
			expect(parentModel).notTo(beNil());

			NSMutableArray *orderedChildren = [NSMutableArray array];
			NSMutableSet *unorderedChildren = [NSMutableSet set];

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
					@"childID": @(i),
					@"parent2": parentModel
				} error:NULL];
				expect(child).notTo(beNil());

				[orderedChildren addObject:child];
			}

			for (NSUInteger i = 3; i < 6; i++) {
				MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
					@"childID": @(i),
					@"parent1": parentModel
				} error:NULL];
				expect(child).notTo(beNil());

				[unorderedChildren addObject:child];
			}

			parentModel.orderedChildren = orderedChildren;
			parentModel.unorderedChildren = unorderedChildren;
		});

		it(@"should insert a managed object with children", ^{
			__block NSError *error = nil;
			MTLParent *parent = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
			expect(parent).notTo(beNil());
			expect(parent).to(beAnInstanceOf(MTLParent.class));
			expect(error).to(beNil());

			expect(parent.entity).to(equal(parentEntity));
			expect(context.insertedObjects).to(contain(parent));

			expect(parent.date).to(equal(parentModel.date));
			expect(parent.number.stringValue).to(equal(parentModel.numberString));
			expect(parent.string).to(equal(parentModel.requiredString));

			expect(@(parent.orderedChildren.count)).to(equal(@3));
			expect(@(parent.unorderedChildren.count)).to(equal(@3));

			for (NSUInteger i = 0; i < 3; i++) {
				MTLChild *child = parent.orderedChildren[i];
				expect(child).to(beAnInstanceOf(MTLChild.class));

				expect(child.entity).to(equal(childEntity));
				expect(context.insertedObjects).to(contain(child));

				expect(child.childID).to(equal(@(i)));
				expect(child.parent1).to(beNil());
				expect(child.parent2).to(equal(parent));
			}

			for (MTLChild *child in parent.unorderedChildren) {
				expect(child).to(beAnInstanceOf(MTLChild.class));

				expect(child.entity).to(equal(childEntity));
				expect(context.insertedObjects).to(contain(child));

				expect(child.childID).to(beGreaterThanOrEqualTo(@3));
				expect(child.childID).to(beLessThan(@6));

				expect(child.parent1).to(equal(parent));
				expect(child.parent2).to(beNil());
			}

			expect(@([context save:&error])).to(beTruthy());
			expect(error).to(beNil());
		});

		it(@"should return an error if a model object could not be inserted", ^{
			MTLFailureModel *failureModel = [MTLFailureModel modelWithDictionary:@{
				@"notSupported": @"foobar"
			} error:NULL];

			__block NSError *error = nil;
			NSManagedObject *failure =[MTLManagedObjectAdapter managedObjectFromModel:failureModel insertingIntoContext:context error:&error];

			expect(failure).to(beNil());
			expect(error).notTo(beNil());
		});

		it(@"should return an error if model doesn't validate for attribute description", ^{
			MTLParentTestModel *parentModel = [MTLParentTestModel modelWithDictionary:@{} error:NULL];

			NSError *error;
			NSManagedObject *managedObject = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];

			expect(managedObject).to(beNil());
			expect(error).notTo(beNil());
		});

		it(@"should return nil and error with an illegal JSON mapping", ^{
			MTLParent *parent = [MTLParent insertInManagedObjectContext:context];
			expect(parent).notTo(beNil());

			parent.string = @"foobar";

			NSError *error = nil;
			MTLIllegalManagedObjectMappingModel *model = [MTLManagedObjectAdapter modelOfClass:MTLIllegalManagedObjectMappingModel.class fromManagedObject:parent error:&error];
			expect(model).to(beNil());
			expect(error).notTo(beNil());
			expect(error.domain).to(equal(MTLManagedObjectAdapterErrorDomain));
			expect(@(error.code)).to(equal(@(MTLManagedObjectAdapterErrorInvalidManagedObjectMapping)));
		});

		it(@"should return an error if model doesn't validate for insert", ^{
			MTLParentIncorrectTestModel *parentModel = [MTLParentIncorrectTestModel modelWithDictionary:@{} error:NULL];

			NSError *error;
			NSManagedObject *managedObject = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];

			expect(managedObject).to(beNil());
			expect(error).notTo(beNil());
		});

		it(@"should respect the uniqueness constraint", ^{
			NSError *errorOne;
			MTLParent *parentOne = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorOne];
			expect(parentOne).notTo(beNil());
			expect(errorOne).to(beNil());

			NSError *errorTwo;
			MTLParent *parentTwo = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorTwo];
			expect(parentTwo).notTo(beNil());
			expect(errorTwo).to(beNil());

			expect(parentOne.objectID).to(equal(parentTwo.objectID));
		});

		it(@"should update relationships for an existing object", ^{
			NSError *error;
			MTLParent *parentOne = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
			expect(parentOne).notTo(beNil());
			expect(error).to(beNil());
			expect(@(parentOne.orderedChildren.count)).to(equal(@3));
			expect(@(parentOne.unorderedChildren.count)).to(equal(@3));

			MTLChild *child1Parent1 = parentOne.orderedChildren[0];
			MTLChild *child2Parent1 = parentOne.orderedChildren[1];
			MTLChild *child3Parent1 = parentOne.orderedChildren[2];

			MTLParentTestModel *parentModelCopy = [parentModel copy];
			[[parentModelCopy mutableOrderedSetValueForKey:@"orderedChildren"] removeObjectAtIndex:1];

			MTLChildTestModel *childToDeleteModel = [parentModelCopy.unorderedChildren anyObject];
			[[parentModelCopy mutableSetValueForKey:@"unorderedChildren"] removeObject:childToDeleteModel];

			MTLParent *parentTwo = [MTLManagedObjectAdapter managedObjectFromModel:parentModelCopy insertingIntoContext:context error:&error];
			expect(parentTwo).notTo(beNil());
			expect(error).to(beNil());
			expect(@(parentTwo.orderedChildren.count)).to(equal(@2));
			expect(@(parentTwo.unorderedChildren.count)).to(equal(@2));

			for (MTLChild *child in parentTwo.orderedChildren) {
				expect(child.childID).notTo(equal(child2Parent1.childID));
			}

			for (MTLChild *child in parentTwo.unorderedChildren) {
				expect(child.childID).notTo(equal(@(childToDeleteModel.childID)));
			}

			MTLChild *child1Parent2 = parentTwo.orderedChildren[0];
			MTLChild *child2Parent2 = parentTwo.orderedChildren[1];
			expect(child1Parent2).to(equal(child1Parent1));
			expect(child2Parent2).to(equal(child3Parent1));
		});

		it(@"should try to merge existing values before overwriting data", ^{
			NSError *error;
			MTLParent *parentOne = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
			expect(parentOne).notTo(beNil());
			expect(error).to(beNil());

			NSDictionary *updates = @{
				@"date": [NSDate date],
				@"numberString": @"1234",
				@"requiredString": @"We expect this string to be 'merged' after insertion"
			};

			MTLParentMergingTestModel *updatedParentModel = [MTLParentMergingTestModel modelWithDictionary:updates error:NULL];

			expect(parentModel).notTo(beNil());

			BOOL saveSuccessful = [context save:nil];
			expect(@(saveSuccessful)).to(beTruthy());

			NSString *initialValueOfRequiredString = updatedParentModel.requiredString;
			MTLParent *updatedParentOne = [MTLManagedObjectAdapter managedObjectFromModel:updatedParentModel insertingIntoContext:context error:&error];
			expect(updatedParentOne).notTo(beNil());
			expect(updatedParentOne.string).notTo(equal(initialValueOfRequiredString));
			expect(updatedParentOne.string).to(equal(@"merged"));
		});
	});
});

describe(@"with a main queue context", ^{
	__block NSManagedObjectContext *context;

	beforeEach(^{
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		expect(context).notTo(beNil());

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;
	});

	it(@"should not deadlock on the main thread", ^{
		MTLParent *parent = [MTLParent insertInManagedObjectContext:context];
		expect(parent).notTo(beNil());

		parent.string = @"foobar";

		NSError *error = nil;
		MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
		expect(parentModel).to(beAnInstanceOf(MTLParentTestModel.class));
		expect(error).to(beNil());
	});
});

describe(@"with a child that fails serialization", ^{
	__block NSManagedObjectContext *context;

	__block NSEntityDescription *parentEntity;
	__block NSEntityDescription *childEntity;
	__block MTLParentTestModel *parentModel;

	beforeEach(^{
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		expect(context).notTo(beNil());

		context.undoManager = nil;
		context.persistentStoreCoordinator = persistentStoreCoordinator;

		parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
		expect(parentEntity).notTo(beNil());

		childEntity = [NSEntityDescription entityForName:@"BadChild" inManagedObjectContext:context];
		expect(childEntity).notTo(beNil());

		parentModel = [MTLParentTestModel modelWithDictionary:@{
			@"date": [NSDate date],
			@"numberString": @"1234",
			@"requiredString": @"foobar"
		} error:NULL];
		expect(parentModel).notTo(beNil());

		NSMutableArray *orderedChildren = [NSMutableArray array];

		for (NSUInteger i = 3; i < 6; i++) {
			MTLBadChildTestModel *child = [MTLBadChildTestModel modelWithDictionary:@{
				@"childID": @(i)
			} error:NULL];
			expect(child).notTo(beNil());

			[orderedChildren addObject:child];
		}

		parentModel.orderedChildren = orderedChildren;
	});

	it(@"should insert a managed object with children", ^{
		__block NSError *error = nil;
		MTLParent *parent = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
		expect(parent).to(beNil());
		expect(error).notTo(beNil());
		expect(@([context save:&error])).to(beTruthy());
	});
});

QuickSpecEnd
