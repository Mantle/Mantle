//
//  NSValueTransformer+MTLErrorHandling.h
//  Mantle
//
//  Created by Robert Böhnke on 9/30/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// The domain for errors originating from the MTLErrorHandling category on
// NSValueTransformer.
extern NSString * const MTLValueTransformerErrorDomain;

// -transformedValue: or -reverseTransformedValue: returned nil for the given
// value.
extern const NSInteger MTLValueTransformerErrorTransformationFailed;

@interface NSValueTransformer (MTLErrorHandling)

// Transforms a value, returning any error that occurred during transformation.
//
// The default implementation simply invokes -transformedValue: and returns an
// error if it returns nil.
// Subclasses should implement this method and return a more descriptive error
// if appropriate.
//
// value - The value to transform.
// error - If not NULL, this may be set to an error that occurs during
//         transforming value.
//
// Returns the result of the transformation or nil if an error occurred.
- (id)mtl_transformedValue:(id)value error:(NSError **)error;

// Reverse-transforms a value, returning any error that occurred during
// transformation.
//
// The default implementation simply invokes -reverseTransformedValue: and
// returns an error if it returns nil.
// Subclasses should implement this method and return a more descriptive error
// if appropriate.
//
// value - The value to transform.
// error - If not NULL, this may be set to an error that occurs during
//         transforming value.
//
// Returns the result of the reverse transformation or nil if an error occurred.
- (id)mtl_reverseTransformedValue:(id)value error:(NSError **)error;

@end
