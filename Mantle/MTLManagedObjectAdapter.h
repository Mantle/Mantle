//
//  MTLManagedObjectAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-29.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MTLModel;

// A MTLModel object that supports being serialized to and from Core Data as an
// NSManagedObject.
@protocol MTLManagedObjectSerializing
@required

// The Core Data entity that the receiver serializes to and deserializes from.
+ (NSEntityDescription *)managedObjectEntity;

// Specifies how to map property keys to different keys on the receiver's
// +managedObjectEntity.
//
// Entity attributes will be mapped to and from the receiver's properties using
// +entityAttributeTransformerForKey:. Entity relationships will be mapped to
// and from MTLModel objects using +relationshipModelClassesByPropertyKey.
// Fetched properties are not supported.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
//
// Any property keys not present in the dictionary are assumed to match the
// entity key that should be used. Any keys associated with NSNull will not
// participate in managed object serialization.
//
// Returns a dictionary mapping property keys to entity keys (as strings) or
// NSNull values.
+ (NSDictionary *)managedObjectKeysByPropertyKey;

@optional

// Specifies how to convert the given property key to a managed object attribute. If
// reversible, the transformer will also be used to convert the managed object
// attribute back to the property.
//
// If the receiver implements a `+<key>EntityAttributeTransformer` method,
// MTLManagedObjectAdapter will use the result of that method instead.
//
// Returns a value transformer, or nil if no transformation should be performed.
+ (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key;

// Specifies the MTLModel subclasses that should be deserialized to the
// receiver's property keys when a property key corresponds to an entity
// relationship.
//
// In other words, the dictionary returned by this method is used to decode
// managed object relationships into MTLModels (or collections thereof) set on
// the receiver.
//
// If a property key is omitted from the returned dictionary, and the receiver's
// +managedObjectEntity has a relationship at the corresponding key, an
// exception will be thrown during deserialization.
//
// Subclasses overriding this method should combine their values with those of
// `super`.
+ (NSDictionary *)relationshipModelClassesByPropertyKey;

// Overridden to deserialize a different class instead of the receiver, based on
// information in the provided object.
//
// This is mostly useful for class clusters, where the abstract base class would
// be passed into +[MTLManagedObjectAdapter
// modelOfClass:fromManagedObject:error:], but a subclass should be instantiated
// instead.
//
// managedObject - The object that will be deserialized.
//
// Returns the class that should be instantiated (which may be the receiver), or
// nil to abort parsing (e.g., if the data is invalid).
+ (Class)classForDeserializingManagedObject:(NSManagedObject *)managedObject;

@end

// Converts a MTLModel object to and from an NSManagedObject.
@interface MTLManagedObjectAdapter : NSObject

// Attempts to deserialize an NSManagedObject into a MTLModel object.
//
// modelClass    - The MTLModel subclass to return. This class must conform to
//                 <MTLManagedObjectSerializing>. This argument must not be nil.
// managedObject - The managed object to deserialize. If this argument is nil,
//                 the method returns nil.
// error         - If not NULL, this may be set to an error that occurs during
//                 deserialization or initializing an instance of `modelClass`.
//
// Returns an instance of `modelClass` upon success, or nil if an error
// occurred.
+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject error:(NSError **)error;

// Serializes a MTLModel into an NSManagedObject.
//
// model   - The model object to serialize. This argument must not be nil.
// context - The context into which to insert the created managed object. This
//           argument must not be nil.
// error   - If not NULL, this may be set to an error that occurs during
//           serialization or insertion.
+ (NSManagedObject *)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error;

@end
