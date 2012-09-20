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

+ (NSDictionary *)defaultValuesForKeys {
	return @{ @"count": @(1) };
}

+ (NSDictionary *)dictionaryKeysByPropertyKey {
	if (modelVersion == 0) {
		return @{ @"name": @"mav_name", @"count": @"mav_count" };
	} else {
		return @{ @"name": @"username" };
	}
}

+ (NSDictionary *)migrateDictionaryRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(fromVersion == 0);

	return @{
		@"username": [@"M: " stringByAppendingString:[dictionary objectForKey:@"mav_name"]],
		@"count": [dictionary objectForKey:@"mav_count"]
	};
}

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	return [*name length] < 10;
}

+ (NSValueTransformer *)propertyTransformerForCount {
	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str) {
			return @(str.integerValue);
		}
		reverseBlock:^(NSNumber *num) {
			return num.stringValue;
		}];
}

- (id)countMergedFromModel:(MTLTestModel *)model {
	return @(self.count + model.count);
}

@end
