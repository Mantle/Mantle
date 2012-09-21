//
//  MTLModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// An abstract base class for model objects, using reflection to provide
// sensible default behaviors.
//
// The default implementations of <NSCopying>, -hash, and -isEqual: all make use
// of the dictionaryValue property. The default implementation of <NSCoding>
// will archive and unarchive the externalRepresentation of the instance.
//
@interface MTLModel : NSObject <NSCoding, NSCopying>

// Returns a new instance of the receiver initialized using
// -initWithDictionaryValue:.
+ (instancetype)modelWithDictionaryValue:(NSDictionary *)dictionaryValue;

// Returns a new instance of the receiver initialized using
// -initWithExternalRepresentation:.
+ (instancetype)modelWithExternalRepresentation:(NSDictionary *)externalRepresentation;

// Initializes the receiver using the property keys and values in the given
// dictionary.
//
// Any NSNull values will be converted to nil before being used. KVC validation
// methods will be automatically invoked for all of the properties given.
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithDictionaryValue:(NSDictionary *)dictionaryValue;

// Invokes -initWithDictionaryValue: after mapping the given external
// representation using +externalRepresentationKeysByPropertyKey and
// +transformerForPropertyKey:.
//
// Any NSNull values will be converted to nil before being used. KVC validation
// methods will be automatically invoked for any transformed values.
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithExternalRepresentation:(NSDictionary *)externalRepresentation;

// Specifies how to map @property keys to different keys for
// -initWithExternalRepresentation: and -externalRepresentation. Subclasses
// overriding this method should combine their values with those of super.
//
// Returns an empty dictionary.
+ (NSDictionary *)externalRepresentationKeysByPropertyKey;

// Specifies how to convert an -initWithExternalRepresentation: value to the
// given @property key. If reversible, the transformer will also be used to
// convert the property value back for -externalRepresentation.
//
// By default, this method looks for a `+<key>Transformer` method on
// the receiver, and invokes it if found.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)transformerForKey:(NSString *)key;

// A dictionary representing the properties of the receiver.
//
// The default implementation of this property finds all @property declarations
// (except for those on MTLModel itself) and combines their values into
// a dictionary, with any nil values represented by NSNull.
//
// This property must never be nil.
@property (nonatomic, copy, readonly) NSDictionary *dictionaryValue;

// The dictionaryValue of the receiver, mapped using
// +externalRepresentationKeysByPropertyKey and any reversible transformers
// returned by +transformerForPropertyKey:. The resulting dictionary is suitable
// for serialization.
//
// This property must never be nil.
@property (nonatomic, copy, readonly) NSDictionary *externalRepresentation;

// The version of this MTLModel subclass.
//
// Returns 0.
+ (NSUInteger)modelVersion;

// Migrates an external representation from an older model version. This method
// will be invoked from -initWithCoder: if an older version of the receiver is
// unarchived.
//
// Returns `dictionary` without any changes. Subclasses may return nil if
// unarchiving should fail.
+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)externalRepresentation fromVersion:(NSUInteger)fromVersion;

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object, giving precedence to the other model object.
//
// By default, this method looks for a `-merge<Key>FromModel:` method on the
// receiver, and invokes it if found. If not found, and `model` is not nil, the
// value for the given key is taken from `model`.
- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model;

// Merges the values of the given model object into the receiver, using
// -mergeValueForKey:fromModel: for each @property declared on the receiver.
//
// `model` must be an instance of the receiver's class or a subclass thereof.
- (void)mergeValuesForKeysFromModel:(MTLModel *)model;

@end
