//
//  MTLTransformerErrorHandling.h
//  Mantle
//
//  Created by Robert Böhnke on 10/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// This protocol can be implemented by NSValueTransformer subclasses to
// communicate errors that occur during transformation.
@protocol MTLTransformerErrorHandling <NSObject>

// Transforms a value, returning any error that occurred during transformation.
//
// value - The value to transform.
// error - If not NULL, this may be set to an error that occurs during
//         transforming value.
//
// Returns the result of the transformation or nil if an error occurred.
- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@optional

// Reverse-transforms a value, returning any error that occurred during
// transformation.
//
// value - The value to transform.
// error - If not NULL, this may be set to an error that occurs during
//         transforming value.
//
// Returns the result of the reverse transformation or nil if an error occurred.
- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@end
