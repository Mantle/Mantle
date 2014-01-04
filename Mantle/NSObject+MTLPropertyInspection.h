//
//  NSObject+MTLPropertyInspection.h
//  Mantle
//
//  Created by Robert Böhnke on 31/12/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MTLPropertyInspection)

// Returns the class of the property with the given key. Returns `nil` if there
// is no property that maches the key or it is a primitive property.
+ (Class)mtl_classOfPropertyWithKey:(NSString *)key;

// Returns the type encoding of the property with the given key. Returns NULL if
// there is no property that maches the key or it wasn't declared using a
// @property statement.
// You must free() the returned pointer.
+ (char *)mtl_objCTypeOfPropertyWithKey:(NSString *)key;

@end
