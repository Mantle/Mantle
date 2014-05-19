//
//  MTLTestManagedObjectModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
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
	[self willChangeValueForKey:@"count"];
    [self setPrimitiveValue:[NSNumber numberWithUnsignedInteger:count] forKey:@"count"];
    [self didChangeValueForKey:@"count"];
}

- (NSUInteger)count {
    NSUInteger a;
	
    [self willAccessValueForKey:@"count"];
    a = [[self primitiveValueForKey:@"count"] unsignedIntegerValue];
    [self didAccessValueForKey:@"count"];
	
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

@implementation MTLSubclassTestManagedObjectModel

@dynamic role;
@dynamic generation;

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSParameterAssert(moc != nil);
	
	return [NSEntityDescription insertNewObjectForEntityForName:@"SubclassTestManagedObjectModel" inManagedObjectContext:moc];
}

@end

//@implementation MTLArrayTestManagedObjectModel
//
//- (void)setNames:(NSArray *)names {
//	
//}
//
//- (NSArray *)names {
//	return nil;
//}
//
//+ (NSDictionary *)JSONKeyPathsByPropertyKey {
//	return @{
//		@"names": @"users.name"
//	};
//}
//
//@end
//
//@implementation MTLSubstitutingTestManagedObjectModel
//
//+ (NSDictionary *)JSONKeyPathsByPropertyKey {
//	return @{};
//}
//
//+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
//	NSParameterAssert(JSONDictionary != nil);
//
//	if (JSONDictionary[@"username"] == nil) {
//		return nil;
//	} else {
//		return MTLTestManagedObjectModel.class;
//	}
//}
//
//@end
//
//@implementation MTLValidationManagedObjectModel
//
//- (void)setName:(NSString *)name {
//	
//}
//
//- (NSString *)name {
//	return nil;
//}
//
//- (BOOL)validateName:(NSString **)name error:(NSError **)error {
//	if (*name != nil) return YES;
//	if (error != NULL) {
//		*error = [NSError errorWithDomain:MTLTestManagedObjectModelErrorDomain code:MTLTestManagedObjectModelNameMissing userInfo:nil];
//	}
//
//	return NO;
//}
//
//@end
//
//@implementation MTLSelfValidatingManagedObjectModel
//
//- (BOOL)validateName:(NSString **)name error:(NSError **)error {
//	if (*name != nil) return YES;
//
//	*name = @"foobar";
//
//	return YES;
//}
//
//@end
//
//@implementation MTLIllegalJSONMappingManagedObjectModel
//
//+ (NSDictionary *)JSONKeyPathsByPropertyKey {
//	return @{
//		@"name": @"username"
//	};
//}
//
//@end
