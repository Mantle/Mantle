//
//  MAVTestModel.m
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MAVTestModel.h"

@implementation MAVTestModel

+ (NSDictionary *)defaultValuesForKeys {
	return @{ @"count": @(1) };
}

+ (NSDictionary *)dictionaryKeysByPropertyKey {
	return @{ @"name": @"username" };
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

@end
