//
//  MTLTestModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

NSString * const MTLTestModelErrorDomain = @"MTLTestModelErrorDomain";
const NSInteger MTLTestModelNameTooLong = 1;
const NSInteger MTLTestModelNameMissing = 2;

static NSUInteger modelVersion = 1;

@implementation MTLEmptyTestModel
@end

@implementation MTLTestModel

#pragma mark Properties

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if ([*name length] < 10) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestModelErrorDomain code:MTLTestModelNameTooLong userInfo:nil];
	}

	return NO;
}

- (NSString *)dynamicName {
	return self.name;
}

#pragma mark Versioning

+ (void)setModelVersion:(NSUInteger)version {
	modelVersion = version;
}

+ (NSUInteger)modelVersion {
	return modelVersion;
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

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];

	if (modelVersion == 0) {
		[coder encodeObject:self.name forKey:@"mtl_name"];
	}
}

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
	return [super.encodingBehaviorsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary:@{
		@"nestedName": @(MTLModelEncodingBehaviorExcluded)
	}];
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)fromVersion {
	NSParameterAssert(key != nil);
	NSParameterAssert(coder != nil);

	if ([key isEqual:@"name"] && fromVersion == 0) {
		return [@"M: " stringByAppendingString:[coder decodeObjectForKey:@"mtl_name"]];
	}

	return [super decodeValueForKey:key withCoder:coder modelVersion:fromVersion];
}

+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion {
	NSParameterAssert(externalRepresentation != nil);
	NSParameterAssert(fromVersion == 1);

	return @{
		@"name": externalRepresentation[@"username"],
		@"nestedName": externalRepresentation[@"nested"][@"name"],
		@"count": @([externalRepresentation[@"count"] integerValue])
	};
}

#pragma mark Merging

- (void)mergeCountFromModel:(MTLTestModel *)model {
	self.count += model.count;
}

@end

@implementation MTLSubclassTestModel
@end

@implementation MTLArrayTestModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"names": @"users.name"
	};
}

@end

@implementation MTLSubstitutingTestModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{};
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
	NSParameterAssert(JSONDictionary != nil);

	if (JSONDictionary[@"username"] == nil) {
		return nil;
	} else {
		return MTLTestModel.class;
	}
}

@end

@implementation MTLValidationModel

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if (*name != nil) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestModelErrorDomain code:MTLTestModelNameMissing userInfo:nil];
	}

	return NO;
}

@end

@implementation MTLSelfValidatingModel

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if (*name != nil) return YES;

	*name = @"foobar";

	return YES;
}

@end

@implementation MTLIllegalJSONMappingModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"name": @"username"
	};
}

@end
