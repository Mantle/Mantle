//
//  MTLKeyedArchiveAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// Describes how a property should be encoded into a keyed archive by
// MTLKeyedArchiveAdapter.
//
// MTLKeyedArchivingBehaviorUnconditional - The property should always be
//                                          encoded.
// MTLKeyedArchivingBehaviorConditional   - The object should only be encoded if
//                                          unconditionally encoded elsewhere.
//                                          This should only be used for object
//                                          properties.
// MTLKeyedArchivingBehaviorExcluded      - The property should never be
//                                          encoded.
typedef enum : NSUInteger {
    MTLKeyedArchivingBehaviorUnconditional,
    MTLKeyedArchivingBehaviorConditional,
    MTLKeyedArchivingBehaviorExcluded
} MTLKeyedArchivingBehavior;

// A MTLModel object that supports keyed archiving.
@protocol MTLKeyedArchiving
@optional

// Determines how property keys are encoded into a keyed archive.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
//
// Returns a dictionary of property keys associated with boxed
// MTLKeyedArchivingBehavior values.
+ (NSDictionary *)keyedArchivingBehaviorsByPropertyKey;

@end

// Implements <NSCoding> for any MTLModel object that conforms to
// <MTLKeyedArchiving>.
@interface MTLKeyedArchiveAdapter : NSObject <NSCoding>

// The model object that the receiver was initialized with, or that the receiver
// decoded from an archive.
@property (nonatomic, strong, readonly) MTLModel<MTLKeyedArchiving> *model;

// Initializes the receiver from an archive, setting its `model` to the decoded
// model object.
- (id)initWithCoder:(NSCoder *)coder;

// Initializes the receiver with an existing model.
- (id)initWithModel:(MTLModel<MTLKeyedArchiving> *)model;

// Encodes the receiver's `model` into an archive.
//
// This will use the behaviors specified by
// +keyedArchivingBehaviorsByPropertyKey to determine which properties should be
// encoded, and whether they should be encoded conditionally. For any property
// not explicitly mentioned in the dictionary, or if that method is not
// implemented, the behavior is as follows:
//
//  - If the property is of object type, and has `weak` or `unsafe_unretained`
//    semantics, the default behavior is MTLKeyedArchivingBehaviorConditional.
//  - For all other properties, the default behavior is
//    MTLKeyedArchivingBehaviorUnconditional.
- (void)encodeWithCoder:(NSCoder *)coder;

@end
