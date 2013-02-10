//
//  MTLTestModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MTLEmptyTestModel : MTLModel
@end

// Implements the "old style" MTLModel interface, predating external
// representation formats.
@interface MTLOldTestModel : MTLModel

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

// Stored in the external representation as `nested.name`.
@property (nonatomic, copy) NSString *nestedName;

// Should not be stored in the external representation or dictionary value.
@property (nonatomic, copy, readonly) NSString *dynamicName;

@end

// Implements the "new style" MTLModel interface, with multiple external
// representation formats.
@interface MTLNewTestModel : MTLModel

// Defaults to 1. This changes the behavior of some of the receiver's methods to
// emulate a migration.
+ (void)setModelVersion:(NSUInteger)version;

// Must be less than 10 characters.
//
// - MTLModelKeyedArchiveFormat encodes this as-is.
// - MTLModelJSONFormat encodes this as a `username` key.
//
// Both formats will migrate from version 0 from an `old_name` key.
@property (nonatomic, copy) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
//
// - MTLModelKeyedArchiveFormat encodes this as-is.
// - MTLModelJSONFormat encodes this as a string. This format will migrate from
//   version 0 by converting from a number to a string.
@property (nonatomic, assign) NSUInteger count;

// - MTLModelKeyedArchiveFormat does not encode this.
// - MTLModelJSONFormat encodes this as `nested.name`.
@property (nonatomic, copy) NSString *nestedName;

// - MTLModelKeyedArchiveFormat encodes this conditionally.
// - MTLModelJSONFormat does not encode this.
@property (nonatomic, weak) MTLNewTestModel *otherModel;

@end
