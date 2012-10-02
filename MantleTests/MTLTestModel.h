//
//  MTLTestModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MTLTestModel : MTLModel

// Defaults to 1. This changes the behavior of some of the receiver's methods to
// emulate a migration.
+ (void)setModelVersion:(NSUInteger)version;

// Must be less than 10 characters.
//
// The external representation uses a "username" key for this property.
@property (nonatomic, copy) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
//
// The external representation for this property is a string.
@property (nonatomic, assign) NSUInteger count;

// Stored in the external representation as "nested.name".
@property (nonatomic, copy) NSString *nestedName;

@end

@interface MTLEmptyTestModel : MTLModel
@end
