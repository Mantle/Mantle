//
//  MTLModel+Validation.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"

#import "MTLModel+Validation.h"

@implementation MTLModel (Validation)

- (BOOL)validateWithError:(NSError **)error {
	for (NSString *key in self.class.propertyKeys) {
		id value = [self valueForKey:key];

		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id validatedValue = value;

		@try {
			if (![self validateValue:&validatedValue forKey:key error:error]) return NO;

			if (value != validatedValue) {
				[self setValue:validatedValue forKey:key];
			}
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);

			// Fail fast in Debug builds.
			#if DEBUG
			@throw ex;
			#else
			if (error != NULL) {
				*error = [NSError mtl_modelErrorWithException:ex];
			}

			return NO;
			#endif
		}
	}

	return YES;
}

@end
