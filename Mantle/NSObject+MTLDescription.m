//
//  NSObject+MTLDescription.m
//  Mantle
//
//  Created by William Green on 2015-07-07.
//  Copyright (c) 2015 GitHub. All rights reserved.
//

#import "NSObject+MTLDescription.h"

@implementation NSObject (MTLDescription)

- (NSString *)mtl_description {
	if ([self conformsToProtocol:@protocol(NSFastEnumeration)]) {
		// Print the container
		NSMutableArray *itemDescriptions = [NSMutableArray array];
		for (NSObject *obj in (id<NSFastEnumeration>)self) {
			// TODO: support objects that conform to <NSObject> but are not NSObjects
			NSString *itemDescription;
			if ([self respondsToSelector:@selector(objectForKeyedSubscript:)]) {
				// Use dictionary syntax
				NSObject *value = [(id)self objectForKeyedSubscript:obj];
				NSString *valueDescription;
				if ([value isKindOfClass:[NSString class]]) {
					// Quote strings if they are values
					valueDescription = [NSString stringWithFormat:@"\"%@\"", value];
				} else {
					valueDescription = [value mtl_description];
				}
				itemDescription = [NSString stringWithFormat:@"%@ = %@", [obj mtl_description], valueDescription];
			} else {
				itemDescription = [obj mtl_description];
			}
			[itemDescriptions addObject:[itemDescription stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
		}

		// Syntax: Dictionary = {}, Array = [], Set = ()
		NSString *containerStart;
		NSString *containerEnd;
		if ([self respondsToSelector:@selector(objectForKeyedSubscript:)]) {
			containerStart = @"{";
			containerEnd   = @"}";
		} else if ([self respondsToSelector:@selector(objectAtIndexedSubscript:)]) {
			containerStart = @"[";
			containerEnd   = @"]";
		} else {
			containerStart = @"(";
			containerEnd   = @")";
		}
		return [NSString stringWithFormat:@"%@\n\t%@\n%@", containerStart, [itemDescriptions componentsJoinedByString:@",\n\t"], containerEnd];
	} else {
		return [self description];
	}
}

@end
