//
//  MAVTestModel.m
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MAVTestModel.h"

static NSUInteger modelVersion = 1;

@implementation MAVTestModel

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

- (BOOL)validateCount:(id *)count error:(NSError **)error {
	if ([*count isKindOfClass:[NSString class]]) {
		*count = [NSNumber numberWithInteger:[*count integerValue]];
	}

	return YES;
}

- (id)countMergedFromModel:(MAVTestModel *)model {
	return @(self.count + model.count);
}

@end
