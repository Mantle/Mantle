//
//  MTLManagedObjectModel.h
//  Mantle
//
//  Created by Christian Bianciotto on 14/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "MTLBaseModel.h"

// An abstract base class for model objects, using reflection to provide
// sensible default behaviors.
@interface MTLManagedObjectModel : NSManagedObject <MTLBaseModelProtocol>

// Initializes the receiver using key-value coding, setting the keys and values
// in the given dictionary.
//
// dictionaryValue - Property keys and values to set on the receiver. Any NSNull
//                   values will be converted to nil before being used. KVC
//                   validation methods will automatically be invoked for all of
//                   the properties given. If nil, this method is equivalent to
//                   -init.
// error           - If not NULL, this may be set to any error that occurs
//                   (like a KVC validation error).
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

// Re-initializes the receiver using key-value coding, setting the keys and
// values in the given dictionary.
//
// dictionaryValue - Property keys and values to set on the receiver. Any NSNull
//                   values will be converted to nil before being used. KVC
//                   validation methods will automatically be invoked for all of
//                   the properties given. If nil, this method is equivalent to
//                   -init.
// error           - If not NULL, this may be set to any error that occurs
//                   (like a KVC validation error).
//
// Returns YES if model object are re-initialized, or NO if validation failed.
- (BOOL)updateWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

// Initializes the receiver with default values.
//
// This is the designated initializer for this class.
- (instancetype)init;

// By default, this method looks for a `-merge<Key>FromModel:` method on the
// receiver, and invokes it if found. If not found, and `model` is not nil, the
// value for the given key is taken from `model`.
- (void)mergeValueForKey:(NSString *)key fromModel:(id<MTLBaseModelProtocol>)model;

// Merges the values of the given model object into the receiver, using
// -mergeValueForKey:fromModel: for each key in +propertyKeys.
//
// `model` must be an instance of the receiver's class or a subclass thereof.
- (void)mergeValuesForKeysFromModel:(id<MTLBaseModelProtocol>)model;

// The storage behavior of a given key.
//
// The default implementation returns MTLPropertyStorageNone for properties that
// are readonly and not backed by an instance variable and
// MTLPropertyStoragePermanent otherwise.
//
// Subclasses can use this method to prevent MTLModel from resolving circular
// references by returning MTLPropertyStorageTransitory.
//
// Returns the storage behavior for a given key on the receiver.
+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey;

// Can not override isEqual: (runtime exception) on NSManagedObject, use NSManagedObject
// implementation.
//- (BOOL)isEqual:(id)object;

// A string that describes the contents of the receiver.
//
// The default implementation is based on the receiver's class and all its
// properties for which +storageBehaviorForPropertyWithKey: returns
// MTLPropertyStoragePermanent.
- (NSString *)description;

@end

// Implements validation logic for MTLModel.
@interface MTLManagedObjectModel (Validation)

// Validates the model.
//
// The default implementation simply invokes -validateValue:forKey:error: with
// all +propertyKeys and their current value. If -validateValue:forKey:error:
// returns a new value, the property is set to that new value.
//
// error - If not NULL, this may be set to any error that occurs during
//         validation
//
// Returns YES if the model is valid, or NO if the validation failed.
- (BOOL)validate:(NSError **)error;

@end
