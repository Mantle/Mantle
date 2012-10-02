//
//  MTLTestModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

static NSUInteger modelVersion = 1;

@implementation MTLTestModel

+ (void)setModelVersion:(NSUInteger)version {
	modelVersion = version;
}

+ (NSUInteger)modelVersion {
	return modelVersion;
}

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;

	self.count = 1;
	return self;
}

+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey {
	if (modelVersion == 0) {
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

- (void)mergeCountFromModel:(MTLTestModel *)model {
	self.count += model.count;
}

@end

@implementation MTLEmptyTestModel
@end
