//
//  NSArray+MAVManipulationAdditions.h
//  Maverick
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (MAVManipulationAdditions)

// The first object in the array or nil if the array is empty.
@property (nonatomic, readonly, strong) id mav_firstObject;

// Returns a new array without all instances of the given object.
- (instancetype)mav_arrayByRemovingObject:(id)object;

// Returns a new array without the first object. If the array is empty, it
// returns the empty array.
- (instancetype)mav_arrayByRemovingFirstObject;

// Returns a new array without the last object. If the array is empty, it
// returns the empty array.
- (instancetype)mav_arrayByRemovingLastObject;

@end
