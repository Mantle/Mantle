//
//  MTLIdentityMapping.h
//  Mantle
//
//  Created by Robert Böhnke on 10/23/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// Creates an identity mapping for serialization.
//
// class - A subclass of MTLModel.
//
// Returns a dictionary that maps all properties of the given class to
// themselves.
extern NSDictionary *MTLIdentityMappingForClass(Class class);
