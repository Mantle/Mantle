//
//  MTLTestManagedObjectModel.m
//  Mantle
//
//  Created by Christian Bianciotto on 2014-05-19.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestManagedObjectModel.h"

NSString * const MTLTestManagedObjectModelErrorDomain = @"MTLTestManagedObjectModelErrorDomain";
const NSInteger MTLTestManagedObjectModelNameTooLong = 1;
const NSInteger MTLTestManagedObjectModelNameMissing = 2;

@implementation MTLEmptyTestManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"EmptyTestManagedObjectModel" inManagedObjectContext:moc];
}

@end

@implementation MTLTestManagedObjectModel

@dynamic name;
@dynamic nestedName;
@dynamic count;
@dynamic weakModel;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"TestManagedObjectModel" inManagedObjectContext:moc];
}

#pragma mark Properties

- (void)setCount:(NSUInteger)count {
	[self willChangeValueForKey:__PROPERTY__];
	[self setPrimitiveValue:[NSNumber numberWithUnsignedInteger:count] forKey:__PROPERTY__];
	[self didChangeValueForKey:__PROPERTY__];
}

- (NSUInteger)count {
	NSUInteger a;
	
	[self willAccessValueForKey:__PROPERTY__];
	a = [[self primitiveValueForKey:__PROPERTY__] unsignedIntegerValue];
	[self didAccessValueForKey:__PROPERTY__];
	
	return a;
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if ([*name length] < 10) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestManagedObjectModelErrorDomain code:MTLTestManagedObjectModelNameTooLong userInfo:nil];
	}

	return NO;
}

- (NSString *)dynamicName {
	return self.name;
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"name": @"username",
		@"nestedName": @"nested.name",
		@"weakModel": NSNull.null,
	};
}

+ (NSValueTransformer *)countJSONTransformer {
	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str) {
			return @(str.integerValue);
		}
		reverseBlock:^(NSNumber *num) {
			return num.stringValue;
		}];
}

#pragma mark Merging

- (void)mergeCountFromModel:(MTLTestManagedObjectModel *)model {
	self.count += model.count;
}

@end

@implementation MTLArrayTestManagedObjectModel

@synthesize names;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"ArrayTestManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
			 @"names": @"users.name"
			 };
}

@end

@implementation MTLSubclassTestManagedObjectModel

@dynamic role;
@dynamic generation;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"SubclassTestManagedObjectModel" inManagedObjectContext:moc];
}

@end

@implementation MTLSubstitutingTestManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"SubstitutingTestManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{};
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
	NSParameterAssert(JSONDictionary != nil);
	
	if (JSONDictionary[@"username"] == nil) {
		return nil;
	} else {
		return MTLTestManagedObjectModel.class;
	}
}

@end

@implementation MTLValidationManagedObjectModel

@dynamic name;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"ValidationManagedObjectModel" inManagedObjectContext:moc];
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if (*name != nil) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestManagedObjectModelErrorDomain code:MTLTestManagedObjectModelNameMissing userInfo:nil];
	}

	return NO;
}

@end

@implementation MTLSelfValidatingManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"SelfValidatingManagedObjectModel" inManagedObjectContext:moc];
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if (*name != nil) return YES;
	
	*name = @"foobar";
	
	return YES;
}

@end

@implementation MTLIllegalJSONMappingManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"IllegalJSONMappingManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
			 @"name": @"username"
			 };
}

@end
