//
//  MAVTestModel.h
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MAVTestModel : MAVModel

// Defaults to 1. This changes the behavior of some of the receiver's methods to
// emulate a migration.
+ (void)setModelVersion:(NSUInteger)version;

// Must be less than 10 characters.
//
// Represented as "username" in dictionary representations.
@property (nonatomic, copy, readonly) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
//
// Can be initialized from a string.
@property (nonatomic, assign, readonly) NSUInteger count;

@end
