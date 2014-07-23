//
//  MTLManagedObject.m
//  Mantle
//
//  Created by Robert Böhnke on 17/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLValidateAndSetValue.h"

#import "MTLManagedObject.h"

@implementation MTLManagedObject

#pragma mark Lifecycle

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
	return [[self alloc] initWithDictionary:dictionaryValue error:error];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
	NSEntityDescription *entityDescription = self.class.entityDescription;

	NSAssert([entityDescription.managedObjectClassName isEqualToString:NSStringFromClass(self.class)], @"+entityDescription must match class %@, got %@.", self.class, entityDescription.managedObjectClassName);

	self =  [super initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
	if (self == nil) return self;

	for (NSString *key in dictionaryValue) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionaryValue objectForKey:key];

		if ([value isEqual:NSNull.null]) value = nil;

		BOOL success = MTLValidateAndSetValue(self, key, value, YES, error);
		if (!success) return nil;
	}

	return self;
}

#pragma mark MTLManagedObject

+ (NSEntityDescription *)entityDescription {
	return nil;
}

#pragma mark MTLModel

+ (NSSet *)propertyKeys {
	NSMutableSet *propertyKeys = [NSMutableSet set];

	for (NSPropertyDescription *description in self.entityDescription.properties) {
		[propertyKeys addObject:description.name];
	}

	return propertyKeys;
}

- (NSDictionary *)dictionaryValue {
	return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
}

- (void)mergeValueForKey:(NSString *)key fromModel:(id<MTLModel>)model {
	[self setValue:[(id)model valueForKey:key] forKey:key];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue error:NULL];
}

@end
