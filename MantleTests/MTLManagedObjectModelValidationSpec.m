//
//  MTLModelValidationSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

#import "MTLTestManagedObjectModel.h"

SpecBegin(MTLManagedObjectModelValidation)

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

it(@"should fail with incorrect values", ^{
	MTLValidationManagedObjectModel *model = [MTLValidationManagedObjectModel insertInManagedObjectContext:context];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	expect(success).to.beFalsy();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestManagedObjectModelErrorDomain);
	expect(error.code).to.equal(MTLTestManagedObjectModelNameMissing);
});

it(@"should succeed with correct values", ^{
	MTLValidationManagedObjectModel *model = [MTLValidationManagedObjectModel insertInManagedObjectContext:context];
	NSError *error = nil;
	BOOL update = [model updateWithDictionary:@{ @"name": @"valid" } error:&error];
	expect(update).notTo.beFalsy();
	expect(error).to.beNil();

	NSError *validateError = nil;
	BOOL success = [model validate:&validateError];
	expect(success).to.beTruthy();

	expect(error).to.beNil();
});

it(@"should apply values returned from -validateValue:error:", ^{
	MTLSelfValidatingManagedObjectModel *model = [MTLSelfValidatingManagedObjectModel insertInManagedObjectContext:context];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	expect(success).to.beTruthy();

	expect(model.name).to.equal(@"foobar");

	expect(error).to.beNil();
});

SpecEnd
