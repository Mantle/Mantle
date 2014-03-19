//
//  NSDictionary+MTLJSONKeyPath.m
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLJSONAdapter.h"

#import "NSDictionary+MTLJSONKeyPath.h"

@implementation NSDictionary (MTLJSONKeyPath)

- (id)mtl_resolveJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error {
	NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];

	id result = self;
	for (NSString *component in components) {
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

		result = [result objectForKey:component];
	}

	if (success != NULL) *success = YES;

	return result;
}

@end