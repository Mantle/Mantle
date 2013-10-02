//
//  MTLUppercasingValueTransformer.m
//  Mantle
//
//  Created by Robert Böhnke on 10/3/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLUppercasingValueTransformer.h"

@implementation MTLUppercasingValueTransformer

+ (Class)transformedValueClass {
	return NSString.class;
}

- (id)transformedValue:(id)value {
	if ([value isKindOfClass:NSString.class]) {
		return [value uppercaseString];
	} else {
		return nil;
	}
}

- (id)reverseTransformedValue:(id)value {
	if ([value isKindOfClass:NSString.class]) {
		return [value lowercaseString];
	} else {
		return nil;
	}
}

@end
