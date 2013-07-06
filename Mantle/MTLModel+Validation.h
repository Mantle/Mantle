//
//  MTLModel+Validation.h
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>

// Implements validation logic for MTLModel.
@interface MTLModel (Validation)

// Validates the model.
//
// The default implementation simply invokes -validateValue:forKey:error: with
// all propertyKeys and their current value. If validating yields a new value,
// it replaces the old one.
//
// error - If not NULL, this may be set to any error that occurs during
//         validation
//
// Returns YES if the model is valid, or NO if the validation failed.
- (BOOL)validateWithError:(NSError **)error;

@end
