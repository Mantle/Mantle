//
//  MTLManagedObjectSubclasses.m
//  Mantle
//
//  Created by Robert Böhnke on 17/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLManagedObjectSubclasses.h"

@implementation MTLManagedObjectParent

@dynamic date;
@dynamic number;
@dynamic string;
@dynamic url;

+ (NSEntityDescription *)entityDescription {
	static NSManagedObjectModel *model;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"MTLManagedObjectTest" withExtension:@"momd"];

		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
	});

	return [model entitiesByName][@"Parent"];
}

@end
