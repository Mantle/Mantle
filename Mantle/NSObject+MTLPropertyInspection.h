//
//  NSObject+MTLPropertyInspection.h
//  Mantle
//
//  Created by Robert Böhnke on 31/12/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MTLPropertyInspection)

// Returns the class of the property with the given key or `nil` if it's a
// primitive property.
+ (Class)mtl_classOfPropertyWithKey:(NSString *)key;

// Returns the type encoding of the property with the given key.
+ (const char *)mtl_objCTypeOfPropertyWithKey:(NSString *)key;

@end
