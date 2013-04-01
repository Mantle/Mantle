//
//  MTLManagedObjectAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-29.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLManagedObjectAdapter.h"
#import "MTLModel.h"

@implementation MTLManagedObjectAdapter

+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject error:(NSError **)error {
	Class managedObjectClass = NSClassFromString(@"NSManagedObject");
	NSAssert(managedObjectClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");

	return nil;
}

+ (NSManagedObject *)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error {
	Class managedObjectClass = NSClassFromString(@"NSManagedObject");
	NSAssert(managedObjectClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");

	return nil;
}

@end
