//
//  MAVModel.h
//  Maverick
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
@interface MAVModel : NSObject <NSCoding, NSCopying>

// Creates and returns a new instance of the receiver, initialized using
// -initWithDictionary:.
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

// Initializes the receiver using the keys and values in the given dictionary,
// mapped using +dictionaryKeysByPropertyKey.
//
// KVC validation methods will be automatically invoked when using this
// initializer. Validation can be used to verify values or convert between
// types.
//
// This is the designated initializer for this class.
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Can be overridden by subclasses to specify default values for properties on
// this class.
//
// The keys of this dictionary should match @property keys, _not_ dictionary
// keys specified by +dictionaryKeysByPropertyKey.
//
// The default implementation returns an empty dictionary.
+ (NSDictionary *)defaultValuesForKeys;

// Can be overridden by subclasses to map @property keys (the keys in the
// returned dictionary) to different keys for -initWithDictionary: and
// -dictionaryRepresentation (the values).
//
// The default implementation returns an empty dictionary.
+ (NSDictionary *)dictionaryKeysByPropertyKey;

// A dictionary representing the properties of the receiver, mapped using
// +dictionaryKeysByPropertyKey.
//
// The default implementation of this property finds all @property declarations
// (except for those on MAVModel) and combines their values into a dictionary.
// Any nil values will be represented by NSNull.
//
// This property must never return nil.
@property (nonatomic, copy, readonly) NSDictionary *dictionaryRepresentation;

// The version of this model subclass.
//
// The default implementation returns 0.
+ (NSUInteger)modelVersion;

// Invoked from -initWithCoder: if an older version of the receiver is
// unarchived. The new, migrated dictionary representation should be returned.
// If nil is returned, unarchival will fail.
//
// The default implementation returns `dictionary` without any changes.
+ (NSDictionary *)migrateDictionaryRepresentation:(NSDictionary *)dictionary fromVersion:(NSUInteger)fromVersion;

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object.
//
// The default implementation of this method looks for a `<key>MergedFromModel:`
// method on the receiver, and invokes it if found. Otherwise, the value for the
// given key on `model` is returned (unless `model` is nil, in which case the
// value from the receiver is used).
- (id)valueForKey:(NSString *)key mergedFromModel:(MAVModel *)model;

// Returns a copy of the receiver merged with the given model object, using
// -valueForKey:mergedWithModel: for each @property key on the receiver.
- (instancetype)modelByMergingFromModel:(MAVModel *)model;

@end
