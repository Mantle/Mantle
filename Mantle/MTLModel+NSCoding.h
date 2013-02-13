//
//  MTLModel+NSCoding.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/MTLModel.h>

// Defines how a MTLModel property key should be encoded into an archive.
//
// MTLModelEncodingBehaviorExcluded      - The property should never be encoded.
// MTLModelEncodingBehaviorUnconditional - The property should always be
//                                         encoded.
// MTLModelEncodingBehaviorConditional   - The object should be encoded only
//                                         if unconditionally encoded elsewhere.
//                                         This should only be used for object
//                                         properties.
typedef enum : NSUInteger {
    MTLModelEncodingBehaviorExcluded = 0,
    MTLModelEncodingBehaviorUnconditional,
    MTLModelEncodingBehaviorConditional,
} MTLModelEncodingBehavior;

// Implements default archiving and unarchiving behaviors for MTLModel.
@interface MTLModel (NSCoding) <NSCoding>

// Initializes the receiver from an archive.
//
// This will decode the original +modelVersion of the archived object, then
// invoke -decodeValueForKey:withCoder:modelVersion: for each of the receiver's
// +propertyKeys.
//
// Returns an initialized model object, or nil if a decoding error occurred.
- (id)initWithCoder:(NSCoder *)coder;

// Archives the receiver using the given coder.
//
// This will encode the receiver's +modelVersion, then the receiver's properties
// according to the behaviors specified in +encodingBehaviorsByPropertyKey.
- (void)encodeWithCoder:(NSCoder *)coder;

// Determines how the +propertyKeys of the class are encoded into an archive.
// The values of this dictionary should be boxed MTLModelEncodingBehavior
// values.
//
// Any keys not present in the dictionary will be excluded from the archive.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
//
// Returns a dictionary mapping the receiver's +propertyKeys to default encoding
// behaviors. If a property is an object with `weak` semantics, the default
// behavior is MTLModelEncodingBehaviorConditional; otherwise, the default is
// MTLModelEncodingBehaviorUnconditional.
+ (NSDictionary *)encodingBehaviorsByPropertyKey;

// Decodes the value of the given property key from an archive.
//
// By default, this method looks for a `-decode<Key>WithCoder:modelVersion:`
// method on the receiver, and invokes it if found. If not found, `-[NSCoder
// decodeObjectForKey:]` will be used with the given `key`.
//
// key          - The property key to decode the value for.
// coder        - The NSCoder representing the archive being decoded.
// modelVersion - The version of the original model object that was encoded.
//
// Returns the decoded and boxed value, or nil if the key was not present.
- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion;

// The version of this MTLModel subclass.
//
// This version number is saved in archives so that later model changes can be
// made backwards-compatible with old versions.
//
// Subclasses should override this method to return a higher version number
// whenever a breaking change is made to the model.
//
// Returns 0.
+ (NSUInteger)modelVersion;

@end

// These methods can be overridden to support archives created by older
// versions of Mantle.
@interface MTLModel (OldArchiveSupport)

// Converts an archived external representation to a dictionary suitable for
// passing to -initWithDictionary:.
//
// externalRepresentation - The decoded external representation of the receiver.
// fromVersion            - The model version at the time the external
//                          representation was encoded.
//
// Returns nil by default, indicating that conversion failed.
+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion;

@end
