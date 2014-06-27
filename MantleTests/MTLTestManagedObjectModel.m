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
	[self setPrimitiveValue:@(count) forKey:__PROPERTY__];
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

#pragma mark Lifecycle

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;
	
	self.count = 1;
	return self;
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	NSMutableDictionary *mapping = [[NSDictionary mtl_identityPropertyMapWithModel:self] mutableCopy];
	
	[mapping removeObjectForKey:@"weakModel"];
	[mapping addEntriesFromDictionary:@{
										@"name": @"username",
										@"nestedName": @"nested.name"
										}];
	
	return mapping;
}

+ (NSValueTransformer *)countJSONTransformer {
	return [MTLValueTransformer
			transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
				return @(str.integerValue);
			}
			reverseBlock:^(NSNumber *num, BOOL *success, NSError **error) {
				return num.stringValue;
			}];
}


#pragma mark Property Storage Behavior

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	if ([propertyKey isEqual:@"weakModel"]) {
		return MTLPropertyStorageTransitory;
	} else {
		return [super storageBehaviorForPropertyWithKey:propertyKey];
	}
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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
			 @"name": @"name"
			 };
}

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

@implementation MTLURLManagedObjectModel

@dynamic URL;

- (void)setURL:(NSURL *)URL {
	[self willChangeValueForKey:[__PROPERTY__ lowercaseString]];
	if(URL) [self setPrimitiveValue:URL.absoluteString forKey:[__PROPERTY__ lowercaseString]];
	else [self setPrimitiveValue:NSNull.null forKey:[__PROPERTY__ lowercaseString]];
	[self didChangeValueForKey:[__PROPERTY__ lowercaseString]];
}

- (NSURL *)URL {
	NSString *a;
	
	[self willAccessValueForKey:[__PROPERTY__ lowercaseString]];
	a = [self primitiveValueForKey:[__PROPERTY__ lowercaseString]];
	[self didAccessValueForKey:[__PROPERTY__ lowercaseString]];
	
	if(a) return [NSURL URLWithString:a];
	return nil;
}

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"URLManagedObjectModel" inManagedObjectContext:moc];
}

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;
	
	self.URL = [NSURL URLWithString:@"http://github.com"];
	return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

@end

@implementation MTLBoolManagedObjectModel

@dynamic flag;

- (void)setFlag:(BOOL)flag {
	[self willChangeValueForKey:__PROPERTY__];
	[self setPrimitiveValue:@(flag) forKey:__PROPERTY__];
	[self didChangeValueForKey:__PROPERTY__];
}

- (BOOL)flag {
	BOOL a;
	
	[self willAccessValueForKey:__PROPERTY__];
	a = [[self primitiveValueForKey:__PROPERTY__] boolValue];
	[self didAccessValueForKey:__PROPERTY__];
	
	return a;
}

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"BoolManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

@end

@implementation MTLIDManagedObjectModel

@dynamic anyObject;

- (void)setAnyObject:(id)anyObject {
	[self willChangeValueForKey:__PROPERTY__];
	[self setPrimitiveValue:[NSKeyedArchiver archivedDataWithRootObject:anyObject] forKey:__PROPERTY__];
	[self didChangeValueForKey:__PROPERTY__];
}

- (id)anyObject {
	id a;
	
	[self willAccessValueForKey:__PROPERTY__];
	a = [NSKeyedUnarchiver unarchiveObjectWithData:[self primitiveValueForKey:__PROPERTY__]];
	[self didAccessValueForKey:__PROPERTY__];
	
	return a;
}

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"IDManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

@end


@implementation MTLMultiKeypathManagedObjectModel

@dynamic range;
@dynamic nestedRange;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"MultiKeypathManagedObjectModel" inManagedObjectContext:moc];
}

- (void)setRange:(NSRange)range {
	[self willChangeValueForKey:@"rangeLocation"];
	[self setPrimitiveValue:@(range.location) forKey:@"rangeLocation"];
	[self didChangeValueForKey:@"rangeLocation"];
	
	[self willChangeValueForKey:@"rangeLength"];
	[self setPrimitiveValue:@(range.length) forKey:@"rangeLength"];
	[self didChangeValueForKey:@"rangeLength"];
}

- (NSRange)range {
	NSRange a;
	
	[self willAccessValueForKey:@"rangeLocation"];
	a.location = [[self primitiveValueForKey:@"rangeLocation"] unsignedIntegerValue];
	[self didAccessValueForKey:@"rangeLocation"];
	
	[self willAccessValueForKey:@"rangeLength"];
	a.length = [[self primitiveValueForKey:@"rangeLength"] unsignedIntegerValue];
	[self didAccessValueForKey:@"rangeLength"];
	
	return a;
}

- (void)setNestedRange:(NSRange)nestedRange {
	[self willChangeValueForKey:@"nestedRangeLocation"];
	[self setPrimitiveValue:@(nestedRange.location) forKey:@"nestedRangeLocation"];
	[self didChangeValueForKey:@"nestedRangeLocation"];
	
	[self willChangeValueForKey:@"nestedRangeLength"];
	[self setPrimitiveValue:@(nestedRange.length) forKey:@"nestedRangeLength"];
	[self didChangeValueForKey:@"nestedRangeLength"];
}

- (NSRange)nestedRange {
	NSRange a;
	
	[self willAccessValueForKey:@"nestedRangeLocation"];
	a.location = [[self primitiveValueForKey:@"nestedRangeLocation"] unsignedIntegerValue];
	[self didAccessValueForKey:@"nestedRangeLocation"];
	
	[self willAccessValueForKey:@"nestedRangeLength"];
	a.length = [[self primitiveValueForKey:@"nestedRangeLength"] unsignedIntegerValue];
	[self didAccessValueForKey:@"nestedRangeLength"];
	
	return a;
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
			 @"range": @[ @"location", @"length" ],
			 @"nestedRange": @[ @"nested.location", @"nested.length" ]
			 };
}

+ (NSValueTransformer *)rangeJSONTransformer {
	return [MTLValueTransformer
			transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
				NSUInteger location = [value[@"location"] unsignedIntegerValue];
				NSUInteger length = [value[@"length"] unsignedIntegerValue];
				
				return [NSValue valueWithRange:NSMakeRange(location, length)];
			} reverseBlock:^(NSValue *value, BOOL *success, NSError **error) {
				NSRange range = value.rangeValue;
				
				return @{
						 @"location": @(range.location),
						 @"length": @(range.length)
						 };
			}];
}

+ (NSValueTransformer *)nestedRangeJSONTransformer {
	return [MTLValueTransformer
			transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
				NSUInteger location = [value[@"nested.location"] unsignedIntegerValue];
				NSUInteger length = [value[@"nested.length"] unsignedIntegerValue];
				
				return [NSValue valueWithRange:NSMakeRange(location, length)];
			} reverseBlock:^(NSValue *value, BOOL *success, NSError **error) {
				NSRange range = value.rangeValue;
				
				return @{
						 @"nested.location": @(range.location),
						 @"nested.length": @(range.length)
						 };
			}];
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	return MTLPropertyStoragePermanent;
}

@end

@implementation MTLNonPropertyManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"NonPropertyManagedObjectModel" inManagedObjectContext:moc];
}

+ (NSSet *)propertyKeys {
	return [NSSet setWithObject:@"homepage"];
}

- (NSURL *)homepage {
	return [NSURL URLWithString:@"about:blank"];
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	if ([propertyKey isEqual:@"homepage"]) {
		return MTLPropertyStoragePermanent;
	}
	
	return [super storageBehaviorForPropertyWithKey:propertyKey];
}

#pragma mark - MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
			 @"homepage": @"homepage"
			 };
}

@end
