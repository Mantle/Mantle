//
//  MTLJSONAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTLModel;

// A MTLModel object that supports being parsed from and serialized to JSON.
@protocol MTLJSONSerializing <MTLModel>
@required

// Specifies how to map property keys to different key paths in JSON.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
//
// Values in the dictionary can either be key paths in the JSON representation
// of the receiver or an array of such key paths. If an array is used, the
// deserialized value will be a dictionary containing all of the keys in the
// array.
//
// Any keys omitted will not participate in JSON serialization.
//
// Examples
//
//     + (NSDictionary *)JSONKeyPathsByPropertyKey {
//         return @{
//             @"name": @"POI.name",
//             @"point": @[ @"latitude", @"longitude" ],
//             @"starred": @"starred"
//         };
//     }
//
// This will map the `starred` property to `JSONDictionary[@"starred"]`, `name`
// to `JSONDictionary[@"POI"][@"name"]` and `point` to a dictionary equivalent
// to:
//
//     @{
//         @"latitude": JSONDictionary[@"latitude"],
//         @"longitude": JSONDictionary[@"longitude"]
//     }
//
// Returns a dictionary mapping property keys to one or multiple JSON key paths
// (as strings or arrays of strings).
+ (NSDictionary *)JSONKeyPathsByPropertyKey;

@optional

// Specifies how to convert a JSON value to the given property key. If
// reversible, the transformer will also be used to convert the property value
// back to JSON.
//
// If the receiver implements a `-<key>JSONTransformer` method, MTLJSONAdapter
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

// The provided JSONDictionary is not valid.
extern const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary;

// Converts a MTLModel object to and from a JSON dictionary.
@interface MTLJSONAdapter : NSObject

// The model object that the receiver was initialized with, or that the receiver
// parsed from a JSON dictionary.
@property (nonatomic, strong, readonly) id<MTLJSONSerializing> model;

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
// error - If not NULL, this may be set to an error that occurs during
//         serializing.
//
// Returns a JSON dictionary, or nil if a serialization error occurred.
+ (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error;

// Initializes the receiver by attempting to parse a JSON dictionary into
// a model object.
//
// JSONDictionary - A dictionary representing JSON data. This should match the
//                  format returned by NSJSONSerialization. If this argument is
//                  nil, the method returns nil and an error with code
//                  MTLJSONAdapterErrorInvalidJSONDictionary.
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
- (id)initWithModel:(id<MTLJSONSerializing>)model;

// Serializes the receiver's `model` into JSON.
//
// error - If not NULL, this may be set to an error that occurs during
//         serializing.
//
// Returns a JSON dictionary, or nil if a serialization error occurred.
- (NSDictionary *)serializeToJSONDictionary:(NSError **)error;

// Looks up the JSON key path in the model's +propertyKeys.
//
// Subclasses may override this method to customize the adapter's serializing
// behavior. You should not call this method directly.
//
// The default implementation returns the result +JSONKeyPathsByPropertyKey
// result of the current model class.
//
// Returns a dictionary mapping property keys to one or multiple JSON key paths
// (as strings or arrays of strings).
- (NSDictionary *)JSONKeyPathsByPropertyKey;

// An optional value transformer that should be used for properties of the given
// class.
//
// A value transformer returned by the model's +JSONTransformerForKey: method
// is given precedence over the one returned by this method.
//
// The default implementation invokes `+<class>JSONTransformer` on the
// receiver if it's implemented. It supports NSURL conversion through
// -NSURLJSONTransformer.
//
// class - The class of the property to serialize. This property must not be
//         nil.
//
// Returns a value transformer or nil if no transformation should be used.
- (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)class;

// A value transformer that should be used for a properties of the given
// primitive type.
//
// If `objCType` matches @encode(id), the value transformer returned by
// -transformerForModelPropertiesOfClass: is used instead.
//
// The default implementation transforms properties that match @encode(BOOL)
// using the MTLBooleanValueTransformerName transformer.
//
// objCType - The type encoding for the value of this property. This is the type
//            as it would be returned by the @encode() directive.
//
// Returns a value transformer or nil if no transformation should be used.
- (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType;

@end

@interface MTLJSONAdapter (ValueTransformers)

// This value transformer is used by MTLJSONAdapter to automatically convert
// NSURL properties to JSON strings and vice versa.
- (NSValueTransformer *)NSURLJSONTransformer;

@end

@class MTLModel;

@interface MTLJSONAdapter (Deprecated)

+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model __attribute__((deprecated("Replaced by +JSONDictionaryFromModel:error:")));

- (NSDictionary *)JSONDictionary __attribute__((deprecated("Replaced by -serializeToJSONDictionary:")));

- (NSString *)JSONKeyPathForPropertyKey:(NSString *)key __attribute__((unavailable("Replaced by -JSONKeyPathsByPropertyKey")));

@end
