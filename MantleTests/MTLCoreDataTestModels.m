//
//  MTLCoreDataTestModels.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-04-05.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataTestModels.h"

@implementation MTLParentTestModel

+ (NSEntityDescription *)managedObjectEntity {
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self] ]];
	return model.entitiesByName[@"Parent"];
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{
		@"numberString": @"number",
	};
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"orderedChildren": MTLChildTestModel.class,
		@"unorderedChildren": MTLChildTestModel.class,
	};
}

@end

@implementation MTLChildTestModel

+ (NSEntityDescription *)managedObjectEntity {
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self] ]];
	return model.entitiesByName[@"Child"];
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
	return @{};
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
	return @{
		@"parent1": MTLParentTestModel.class,
		@"parent2": MTLParentTestModel.class,
	};
}

@end
