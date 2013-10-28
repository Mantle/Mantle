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
@required

// Transforms a value, returning any error that occurred during transformation.
//
// value   - The value to transform.
// success - If not NULL, this shall be set YES to indicate whether the
//           transformation was successful.
// error   - If not NULL, this may be set to an error that occurs during
//           transforming the value.
//
// Returns the result of the transformation which may be nil. Clients should
// inspect the success parameter to decide how to proceed with the result.
- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@optional

// Reverse-transforms a value, returning any error that occurred during
// transformation.
//
// NSValueTransformer subclasses that implement MTLTransformerErrorHandling are
// expected to implement this method if they support reverse transformation.
//
// value   - The value to transform.
// success - If not NULL, this will be set YES to indicate whether the
//           transformation was successful.
// error   - If not NULL, this may be set to an error that occurs during
//           transforming the value.
//
// Returns the result of the reverse transformation which may be nil. Clients
// should inspect the success parameter to decide how to proceed with the
// result.
- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@end
