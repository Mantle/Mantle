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
@optional

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

// Specifies how to convert a JSON value to the given property key. If
// reversible, the transformer will also be used to convert the property value
// back to JSON.
//
// If the receiver implements a `+<key>JSONTransformer` method, MTLJSONAdapter
// will use the result of that method instead.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;

@end

// Converts a MTLModel object to and from a JSON dictionary.
@interface MTLJSONAdapter : NSObject

// The model object that the receiver was initialized with, or that the receiver
// parsed from a JSON dictionary.
@property (nonatomic, strong, readonly) MTLModel<MTLJSONSerializing> *model;

// Initializes the receiver by attempting to parse a JSON dictionary into
// a model object.
//
// JSONDictionary - A dictionary representing JSON data. This should match the
//                  format returned by NSJSONSerialization. If this argument is
//                  nil, the method returns nil.
// modelClass     - The MTLModel subclass to attempt to parse from the JSON.
//                  This class must conform to <MTLJSONSerializing>. This
//                  argument must not be nil.
//
// Returns an initialized adapter upon success, or nil if a parsing error
// occurred.
- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass;

// Initializes the receiver with an existing model.
//
// This is the designated initializer for this class.
//
// model - The model to use for JSON serialization.
- (id)initWithModel:(MTLModel<MTLJSONSerializing> *)model;

// Serializes the receiver's `model` into a JSON dictionary.
- (NSDictionary *)JSONDictionary;

@end
