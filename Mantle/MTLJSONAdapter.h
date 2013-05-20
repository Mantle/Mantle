//
//  MTLJSONAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTLModel;

// A MTLModel object that supports being parsed from and serialized to JSON.
@protocol MTLJSONSerializing
@required

// Specifies how to map property keys to different key paths in JSON.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
//
// Any property keys not present in the dictionary are assumed to match the JSON
// key that should be used. Any keys associated with NSNull will not participate
// in JSON serialization.
//
// Returns a dictionary mapping property keys to JSON key paths (as strings) or
// NSNull values.
+ (NSDictionary *)JSONKeyPathsByPropertyKey;

@optional

// Specifies how to convert a JSON value to the given property key. If
// reversible, the transformer will also be used to convert the property value
// back to JSON.
//
// If the receiver implements a `+<key>JSONTransformer` method, MTLJSONAdapter
// will use the result of that method instead.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;

// Overridden to parse the receiver as a different class, based on information
// in the provided dictionary.
//
// This is mostly useful for class clusters, where the abstract base class would
// be passed into -[MTLJSONAdapter initWithJSONDictionary:modelClass:], but
// a subclass should be instantiated instead.
//
// JSONDictionary - The JSON dictionary that will be parsed.
//
// Returns the class that should be parsed (which may be the receiver), or nil
// to abort parsing (e.g., if the data is invalid).
+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary;

@end

// The domain for errors originating from MTLJSONAdapter.
extern NSString * const MTLJSONAdapterErrorDomain;

// +classForParsingJSONDictionary: returned nil for the given dictionary.
extern const NSInteger MTLJSONAdapterErrorNoClassFound;

// Converts a MTLModel object to and from a JSON dictionary.
@interface MTLJSONAdapter : NSObject

// The model object that the receiver was initialized with, or that the receiver
// parsed from a JSON dictionary.
@property (nonatomic, strong, readonly) MTLModel<MTLJSONSerializing> *model;

// Attempts to parse a JSON dictionary into a model object.
//
// modelClass     - The MTLModel subclass to attempt to parse from the JSON.
//                  This class must conform to <MTLJSONSerializing>. This
//                  argument must not be nil.
// JSONDictionary - A dictionary representing JSON data. This should match the
//                  format returned by NSJSONSerialization. If this argument is
//                  nil, the method returns nil.
// error          - If not NULL, this may be set to an error that occurs during
//                  parsing or initializing an instance of `modelClass`.
//
// Returns an instance of `modelClass` upon success, or nil if a parsing error
// occurred.
+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error;

// Converts a model into a JSON representation.
//
// model - The model to use for JSON serialization. This argument must not be
//         nil.
//
// Returns a JSON dictionary, or nil if a serialization error occurred.
+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model;

// Initializes the receiver by attempting to parse a JSON dictionary into
// a model object.
//
// JSONDictionary - A dictionary representing JSON data. This should match the
//                  format returned by NSJSONSerialization. If this argument is
//                  nil, the method returns nil.
// modelClass     - The MTLModel subclass to attempt to parse from the JSON.
//                  This class must conform to <MTLJSONSerializing>. This
//                  argument must not be nil.
// error          - If not NULL, this may be set to an error that occurs during
//                  parsing or initializing an instance of `modelClass`.
//
// Returns an initialized adapter upon success, or nil if a parsing error
// occurred.
- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error;

// Initializes the receiver with an existing model.
//
// model - The model to use for JSON serialization. This argument must not be
//         nil.
- (id)initWithModel:(MTLModel<MTLJSONSerializing> *)model;

// Serializes the receiver's `model` into JSON.
//
// Returns a JSON dictionary, or nil if a serialization error occurred.
- (NSDictionary *)JSONDictionary;

@end

@interface MTLJSONAdapter (Deprecated)

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary __attribute__((deprecated("Replaced by +modelOfClass:fromJSONDictionary:error:")));
- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass __attribute__((deprecated("Replaced by -initWithJSONDictionary:modelClass:error:")));

@end
