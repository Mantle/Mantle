//
//  MTLTestModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSDictionary+MTLManipulationAdditions.h"

#import "MTLTestModel.h"
#import "NSDictionary+MTLMappingAdditions.h"

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

#pragma mark Property Storage Behavior

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	if ([propertyKey isEqual:@"weakModel"]) {
		return MTLPropertyStorageTransitory;
	} else {
		return [super storageBehaviorForPropertyWithKey:propertyKey];
	}
}

#pragma mark Merging

- (void)mergeCountFromModel:(MTLTestModel *)model {
	self.count += model.count;
}

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
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
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

@implementation MTLURLModel

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

@implementation MTLBoolModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

@end

@implementation MTLIDModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

@end

@implementation MTLNonPropertyModel

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

@interface MTLConformingModel ()

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

@end

@implementation MTLConformingModel

#pragma mark Lifecycle

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
	return [[self alloc] initWithDictionary:dictionaryValue error:error];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
	self = [super init];
	if (self == nil) return nil;

	_name = dictionaryValue[@"name"];

	return self;
}

#pragma mark MTLModel

- (NSDictionary *)dictionaryValue {
	if (self.name == nil) return @{};

	return @{
		@"name": self.name
	};
}

+ (NSSet *)propertyKeys {
	return [NSSet setWithObject:@"name"];
}

- (void)mergeValueForKey:(NSString *)key fromModel:(id<MTLModel>)model {
	if ([key isEqualToString:@"name"]) {
		self.name = [model dictionaryValue][@"name"];
	}
}

- (void)mergeValuesForKeysFromModel:(id<MTLModel>)model {
	self.name = [model dictionaryValue][@"name"];
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"name": @"name"
	};
}

#pragma mark NSObject

- (NSUInteger)hash {
	return self.name.hash;
}

- (BOOL)isEqual:(MTLConformingModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	return self.name == model.name || [self.name isEqual:model.name];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

@end

@implementation MTLStorageBehaviorModel

- (id)notIvarBacked {
	return self;
}

@end

@implementation MTLMultiKeypathModel

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"range": @[ @"location", @"length" ]
	};
}

+ (NSValueTransformer *)rangeJSONTransformer {
	return [MTLValueTransformer
		transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
			NSUInteger location = [value[@"location"] unsignedIntegerValue];
			NSUInteger length = [value[@"length"] unsignedIntegerValue];

			return [NSValue valueWithRange:NSMakeRange(location, length)];
		}
		reverseBlock:^(NSValue *value, BOOL *success, NSError **error) {
			NSRange range = value.rangeValue;

			return @{
				@"location": @(range.location),
				@"length": @(range.length)
			};
		}];
}

@end