//
//  MTLModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// Defines how a MTLModel property key should be encoded into an external
// representation.
//
// MTLModelEncodingBehaviorNone          - The property should never be encoded.
// MTLModelEncodingBehaviorUnconditional - The property should always be
//                                         encoded.
// MTLModelEncodingBehaviorConditional   - The property should be encoded only
//                                         if unconditionally encoded elsewhere.
//                                         This is only honored for
//                                         MTLModelKeyedArchiveFormat by
//                                         default. For all other cases, it
//                                         behaves like
//                                         MTLModelEncodingBehaviorUnconditional.
typedef enum : NSUInteger {
    MTLModelEncodingBehaviorNone,
    MTLModelEncodingBehaviorUnconditional,
    MTLModelEncodingBehaviorConditional
} MTLModelEncodingBehavior;

// An external representation format specifying encoding to or decoding from
// a keyed archive using NSKeyedArchiver and NSKeyedUnarchiver.
extern NSString * const MTLModelKeyedArchiveFormat;

// An external representation format specifying encoding to or decoding from
// a JSON dictionary.
extern NSString * const MTLModelJSONFormat;

// An abstract base class for model objects, using reflection to provide
// sensible default behaviors.
//
// MTLModel has a concept of an "external representation," which is like
// a serialized version of the model object. By default, the only external
// representation formats defined are MTLModelKeyedArchiveFormat and
// MTLModelJSONFormat, but applications can use their own format names and
// implement their own serialization behaviors as desired.
@interface MTLModel : NSObject <NSCoding, NSCopying>

// Returns a new instance of the receiver initialized using
// -initWithDictionary:.
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue;

// Returns a new instance of the receiver initialized using
// -initWithExternalRepresentation:inFormat:.
+ (instancetype)modelWithExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat;

// Initializes the receiver with default values.
//
// This is the designated initializer for this class.
- (instancetype)init;

// Initializes the receiver using key-value coding, setting the keys and values
// in the given dictionary. If `dictionaryValue` is nil, this method is equivalent
// to -init.
//
// Any NSNull values will be converted to nil before being used. KVC validation
// methods will be automatically invoked for all of the properties given.
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue;

// Invokes -initWithDictionary: after mapping the given external
// representation using +keyPathsByPropertyKeyForExternalRepresentationFormat:
// and +transformerForPropertyKey:externalRepresentationFormat:.
//
// Any NSNull values will be converted to nil before being used. KVC validation
// methods will be automatically invoked for any transformed values.
//
// Returns an initialized model object, or nil if validation failed or
// `externalRepresentation` was nil.
- (instancetype)initWithExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat;

// Decodes an external representation in MTLModelKeyedArchiveFormat from the
// given coder, migrates it (if necessary) using
// -migrateExternalRepresentation:inFormat:fromVersion:, and then initializes
// the receiver with -initWithExternalRepresentation:inFormat:.
- (instancetype)initWithCoder:(NSCoder *)coder;

// Returns a copy of the receiver, initialized using -initWithDictionary: with
// the receiver's dictionaryValue.
- (instancetype)copyWithZone:(NSZone *)zone;

// Serializes the receiver with the given coder, according to the behaviors
// specified by +encodingBehaviorForPropertyKey:externalRepresentationFormat:.
//
// From the receiver's dictionaryValue, this method retrieves any properties
// that should be encoded, transforms them using
// +keyPathsByPropertyKeyForExternalRepresentationFormat: and any reversible
// transformers returned by
// +transformerForPropertyKey:externalRepresentationFormat:, then encodes them
// according to the specified MTLModelEncodingBehavior.
- (void)encodeWithCoder:(NSCoder *)coder;

// Specifies how to map @property keys to different key paths in the given
// external representation format. Subclasses overriding this method should
// combine their values with those of super.
//
// Any keys not present in the dictionary are assumed to be the same for
// @property declarations and the external representation.
//
// Returns an empty dictionary.
+ (NSDictionary *)keyPathsByPropertyKeyForExternalRepresentationFormat:(NSString *)externalRepresentationFormat;

// Specifies how to transform an external representation value to the given
// @property key. If reversible, the transformer will also be used to convert
// the property value back to its external representation.
//
// By default, this method looks for
// a `+<key>TransformerForExternalRepresentationFormat:` method on the receiver,
// and invokes it if found.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)transformerForPropertyKey:(NSString *)key externalRepresentationFormat:(NSString *)externalRepresentationFormat;

// Returns the keys for all @property declarations, except for properties on
// MTLModel itself.
+ (NSSet *)propertyKeys;

// A dictionary representing the properties of the receiver.
//
// The default implementation combines the values corresponding to all
// +propertyKeys into a dictionary, with any nil values represented by NSNull.
//
// This property must never be nil.
@property (nonatomic, copy, readonly) NSDictionary *dictionaryValue;

// Determines how the given property key should be encoded into the specified
// external representation format.
//
// This method is automatically invoked by -encodeWithCoder: and
// -externalRepresentationInFormat:.
- (MTLModelEncodingBehavior)encodingBehaviorForPropertyKey:(NSString *)key externalRepresentationFormat:(NSString *)externalRepresentationFormat;

// Transforms the receiver's dictionaryValue into the given external
// representation format, suitable for serialization.
//
// The keys in the dictionaryValue are mapped using
// +keyPathsByPropertyKeyForExternalRepresentationFormat:, and the values are
// mapped using any reversible transformers returned by
// +transformerForPropertyKey:externalRepresentationFormat:.
//
// Any keys for which
// -encodingBehaviorForPropertyKey:externalRepresentationFormat: returns
// MTLModelEncodingBehaviorNone will be omitted from the returned dictionary.
// All other keys will be included by default.
//
// For any external representation key paths where values along the path are
// nil (but the final value is not), dictionaries are automatically added so
// that the value can be correctly set at the complete key path.
- (id)externalRepresentationInFormat:(NSString *)externalRepresentationFormat;

// The version of this MTLModel subclass.
//
// Returns 0.
+ (NSUInteger)modelVersion;

// Migrates an external representation in a specified format from an older model
// version.
//
// This method is only invoked by MTLModel from -initWithCoder:, and only if an
// older version of the receiver is unarchived.
//
// Returns `externalRepresentation` without any changes. Subclasses may return
// nil if unarchiving should fail.
+ (NSDictionary *)migrateExternalRepresentation:(id)externalRepresentation inFormat:(NSString *)externalRepresentationFormat fromVersion:(NSUInteger)fromVersion;

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object, giving precedence to the other model object.
//
// By default, this method looks for a `-merge<Key>FromModel:` method on the
// receiver, and invokes it if found. If not found, and `model` is not nil, the
// value for the given key is taken from `model`.
- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model;

// Merges the values of the given model object into the receiver, using
// -mergeValueForKey:fromModel: for each key in +propertyKeys.
//
// `model` must be an instance of the receiver's class or a subclass thereof.
- (void)mergeValuesForKeysFromModel:(MTLModel *)model;

// Returns a hash of the receiver's dictionaryValue.
- (NSUInteger)hash;

// Returns whether `model` is of the exact same class as the receiver, and
// whether its dictionaryValue compares equal to the receiver's.
- (BOOL)isEqual:(MTLModel *)model;

@property (nonatomic, copy, readonly) NSDictionary *externalRepresentation __attribute__((deprecated("Replaced by -externalRepresentationInFormat:")));

+ (instancetype)modelWithExternalRepresentation:(NSDictionary *)externalRepresentation __attribute__((deprecated("Replaced by +modelWithExternalRepresentation:inFormat:")));
- (instancetype)initWithExternalRepresentation:(NSDictionary *)externalRepresentation __attribute__((deprecated("Replaced by +initWithExternalRepresentation:inFormat:")));
+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)externalRepresentation fromVersion:(NSUInteger)fromVersion __attribute__((deprecated("Replaced by +migrateExternalRepresentation:inFormat:fromVersion:")));
+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey __attribute__((deprecated("Replaced by +keyPathsByPropertyKeyForExternalRepresentationFormat:")));
+ (NSValueTransformer *)transformerForKey:(NSString *)key __attribute__((deprecated("Replaced by +transformerForPropertyKey:externalRepresentationFormat:")));

@end
