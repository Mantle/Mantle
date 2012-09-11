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

// Initializes the receiver using the keys and values in the given dictionary,
// mapped using +dictionaryKeysByPropertyKey.
//
// KVC validation methods will be automatically invoked when using this
// initializer. Validation can be used to verify values or convert between
// types.
//
// This is the designated initializer for this class.
- (id)initWithDictionary:(NSDictionary *)dict;

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

@end
