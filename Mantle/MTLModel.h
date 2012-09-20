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
// Subclasses are assumed to be immutable. If this is not the case,
// -copyWithZone: should be overridden to perform a real copy.
//
// The default implementations of <NSCoding>, -hash, and -isEqual: all make use
// of the dictionaryRepresentation property.
//
@interface MTLModel : NSObject <NSCoding, NSCopying>

// Returns a new instance of the receiver initialized using
// -initWithDictionary:.
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

// Initializes the receiver using the keys and values in the given dictionary,
// mapped using +dictionaryKeysByPropertyKey and +propertyTransformerForKey:.
// Any NSNull values will be converted to nil before being used.
//
// After transformation, KVC validation methods will be automatically invoked.
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Initializes the receiver, using KVC to set properties of the receiver
// according to the values in the given dictionary. Any NSNull values will be
// converted to nil before being used.
//
// This is the designated initializer for this class.
- (instancetype)initWithPropertyKeysAndValues:(NSDictionary *)propertyKeysAndValues;

// Specifies default values for properties on this class. Subclasses overriding
// this method should combine their values with those of super.
//
// The keys of this dictionary should match @property keys, _not_ the dictionary
// keys specified by +dictionaryKeysByPropertyKey.
//
// Returns an empty dictionary.
+ (NSDictionary *)defaultValuesForKeys;

// Specifies how to map @property keys to different keys for
// -initWithDictionary: and -dictionaryRepresentation. Subclasses overriding
// this method should combine their values with those of super.
//
// Returns an empty dictionary.
+ (NSDictionary *)dictionaryKeysByPropertyKey;

// Specifies how to convert -initWithDictionary: values to the given @property
// key. If reversible, the transformer will also be used to convert the property
// value back for the -dictionaryRepresentation.
//
// By default, this method looks for a `propertyTransformerFor<Key>:` method on
// the receiver, and invokes it if found.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)propertyTransformerForKey:(NSString *)key;

// A dictionary representing the properties of the receiver, mapped using
// +dictionaryKeysByPropertyKey.
//
// The default implementation of this property finds all @property declarations
// (except for those on MTLModel) and combines their values into a dictionary.
// Any nil values will be represented by NSNull.
//
// This property must never be nil.
@property (nonatomic, copy, readonly) NSDictionary *dictionaryRepresentation;

// The version of this model subclass.
//
// Returns 0.
+ (NSUInteger)modelVersion;

// Migrates a dictionary representation from an older model version. This method
// will be invoked from -initWithCoder: if an older version of the receiver is
// unarchived.
//
// Returns `dictionary` without any changes. Subclasses may return nil if
// unarchiving should fail.
+ (NSDictionary *)migrateDictionaryRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion;

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object, giving precedence to the other model object.
//
// By default, this method looks for a `<key>MergedFromModel:` method on the
// receiver, and invokes it if found.
//
// Returns the merged value. If `<key>MergedFromModel:` is not implemented, the
// value for the given key on `model` is returned (unless `model` is nil, in
// which case the value from the receiver is used).
- (id)valueForKey:(NSString *)key mergedFromModel:(MTLModel *)model;

// Returns a copy of the receiver merged with the given model object, using
// -valueForKey:mergedFromModel: for each @property key on the receiver.
- (instancetype)modelByMergingFromModel:(MTLModel *)model;

@end
