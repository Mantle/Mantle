//
//  NSDictionary+MTLJSONKeyPath.m
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSDictionary+MTLJSONKeyPath.h"

#import "MTLJSONAdapter.h"

static NSArray<NSString *> *componentsFromKeyPath(NSString *keyPath) {
	BOOL dirty = NO;
	NSUInteger start = 0, index = 0, length = keyPath.length;
	NSMutableArray<NSString *> *components = nil;
	while (index < length) {
		unichar character = [keyPath characterAtIndex:index];
		if (character == '\\' && index + 1 < length) {
			unichar literal = [keyPath characterAtIndex:(index + 1)];
			if (literal == '.') {
				index += 2;
				dirty = YES;
			}
		} else if (character == '.') {
			NSString *component = [keyPath substringWithRange:NSMakeRange(start, index - start)];
			if (dirty) {
				component = [component stringByReplacingOccurrencesOfString:@"\\." withString:@"."];
			}
			if (components) {
				[components addObject:component];
			} else {
				components = [[NSMutableArray alloc] initWithObjects:component, nil];
			}
			dirty = NO;
			start = ++index;
		} else {
			index++;
		}
	}

	NSString *component = (start == 0 ? keyPath : [keyPath substringWithRange:NSMakeRange(start, length - start)]);
	if (dirty) {
		component = [component stringByReplacingOccurrencesOfString:@"\\." withString:@"."];
	}
	if (!components) {
		return @[component];
	}
	
	[components addObject:component];
	return components;
}

@implementation NSDictionary (MTLJSONKeyPath)

- (id)mtl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error {
	NSArray<NSString *> *components = componentsFromKeyPath(JSONKeyPath);
	
	id result = self;
	for (NSString *component in components) {
		// Check the result before resolving the key path component to not
		// affect the last value of the path.
		if (result == nil || result == NSNull.null) break;

		if (![result isKindOfClass:NSDictionary.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
			}

			if (success != NULL) *success = NO;

			return nil;
		}

		result = result[component];
	}

	if (success != NULL) *success = YES;

	return result;
}

@end
