//
//  MTLTestModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

static NSUInteger MTLOldTestModelVersion = 1;
static NSUInteger MTLNewTestModelVersion = 1;

@implementation MTLEmptyTestModel
@end

// Ignore deprecation warnings for the implementation of the old MTLModel
// interface.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation MTLOldTestModel

+ (void)setModelVersion:(NSUInteger)version {
	MTLOldTestModelVersion = version;
}

+ (NSUInteger)modelVersion {
	return MTLOldTestModelVersion;
}

- (NSString *)dynamicName {
	return self.name;
}

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;

	self.count = 1;
	return self;
}

+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey {
	if (MTLOldTestModelVersion == 0) {
		return @{ @"name": @"mtl_name", @"count": @"mtl_count", @"nestedName": @"nested.name" };
	} else {
		return @{ @"name": @"username", @"nestedName": @"nested.name" };
	}
}

+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(fromVersion == 0);

	return @{
		@"username": [@"M: " stringByAppendingString:[dictionary objectForKey:@"mtl_name"]],
		@"count": [dictionary objectForKey:@"mtl_count"]
	};
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	return [*name length] < 10;
}

+ (NSValueTransformer *)countTransformer {
	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str) {
			return @(str.integerValue);
		}
		reverseBlock:^(NSNumber *num) {
			return num.stringValue;
		}];
}

- (void)mergeCountFromModel:(MTLOldTestModel *)model {
	self.count += model.count;
}

@end

#pragma clang diagnostic pop

@implementation MTLNewTestModel

+ (void)setModelVersion:(NSUInteger)version {
	MTLNewTestModelVersion = version;
}

+ (NSUInteger)modelVersion {
	return MTLNewTestModelVersion;
}

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;

	self.count = 1;
	return self;
}

+ (NSDictionary *)keyPathsByPropertyKeyForExternalRepresentationFormat:(NSString *)format {
	NSDictionary *keyPaths = [super keyPathsByPropertyKeyForExternalRepresentationFormat:format];

	if ([format isEqual:MTLModelJSONFormat]) {
		keyPaths = [keyPaths mtl_dictionaryByAddingEntriesFromDictionary:@{
			@"name": @"username",
			@"nestedName": @"nested.name",
		}];
	}

	return keyPaths;
}

+ (NSDictionary *)encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:(NSString *)format {
	NSDictionary *behaviors = [super encodingBehaviorsByPropertyKeyForExternalRepresentationFormat:format];

	if ([format isEqual:MTLModelKeyedArchiveFormat]) {
		behaviors = [behaviors mtl_dictionaryByAddingEntriesFromDictionary:@{
			@"nestedName": @(MTLModelEncodingBehaviorNone),
		}];
	} else {
		behaviors = [behaviors mtl_dictionaryByAddingEntriesFromDictionary:@{
			@"otherModel": @(MTLModelEncodingBehaviorNone),
		}];
	}

	return behaviors;
}

+ (NSDictionary *)migrateExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)format fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(externalRepresentation != nil);
	NSParameterAssert(fromVersion == 0);

	if ([format isEqual:MTLModelJSONFormat]) {
		NSMutableDictionary *dict = [externalRepresentation mutableCopy];
		dict[@"name"] = [dict[@"name"] substringToIndex:9];
		return dict;
	}

	return [super migrateExternalRepresentation:externalRepresentation inFormat:format fromVersion:fromVersion];
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	return [*name length] < 10;
}

+ (NSValueTransformer *)countTransformerForExternalRepresentationFormat:(NSString *)format {
	if (![format isEqual:MTLModelJSONFormat]) return nil;

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str) {
			return @(str.integerValue);
		}
		reverseBlock:^(NSNumber *num) {
			return num.stringValue;
		}];
}

- (void)mergeCountFromModel:(MTLNewTestModel *)model {
	self.count += model.count;
}

@end
