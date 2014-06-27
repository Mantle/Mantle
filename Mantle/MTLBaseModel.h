//
//  MTLBaseModel.h
//  Mantle
//
//  Created by Christian Bianciotto on 19/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "MTLBaseModelProtocol.h"

// An static base class for model objects, using reflection on model to provide
// sensible default behaviors.
@interface MTLBaseModel : NSObject

+ (BOOL)updateModel:(id<MTLBaseModelProtocol>)model withDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

@end

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all transitory
// property keys.
static void *MTLModelCachedTransitoryPropertyKeysKey = &MTLModelCachedTransitoryPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all permanent
// property keys.
static void *MTLModelCachedPermanentPropertyKeysKey = &MTLModelCachedPermanentPropertyKeysKey;

// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated. This value
//               must not be nil.
// key         - The name of one of `obj`s properties. This value must not be
//               nil.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error);

@interface MTLBaseModel (Reflection)

// Returns the keys for all @property declarations, except for `readonly`
// properties without ivars, or properties on MTLModel itself.
+ (NSSet *)propertyKeysFromModelClass:(Class<MTLBaseModelProtocol>)modelClass;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStorageTransitory.
+ (NSSet *)transitoryPropertyKeysFromModelClass:(Class<MTLBaseModelProtocol>)modelClass;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStoragePermanent.
+ (NSSet *)permanentPropertyKeysFromModelClass:(Class<MTLBaseModelProtocol>)modelClass;

// A dictionary representing the properties of the receiver.
//
// Combines the values corresponding to all +propertyKeys into a dictionary,
// with any nil values represented by NSNull.
//
// This property must never be nil.
+ (NSDictionary *)dictionaryValueFromModel:(id<MTLBaseModelProtocol>)model;

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
+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey ofModelClass:(Class<MTLBaseModelProtocol>)modelClass;

@end

@interface MTLBaseModel (Merging)

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object, giving precedence to the other model object.
+ (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLBaseModelProtocol> *)sourceModel inModel:(NSObject<MTLBaseModelProtocol> *)destinationModel;

// Merges the values of the given model object into the receiver, using
// -mergeValueForKey:fromModel: for each key in +propertyKeys.
//
// `model` must be an instance of the receiver's class or a subclass thereof.
+ (void)mergeValuesForKeysFromModel:(NSObject<MTLBaseModelProtocol> *)sourceModel inModel:(NSObject<MTLBaseModelProtocol> *)destinationModel;

@end

@interface MTLBaseModel (Validation)

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
+ (BOOL)validateModel:(NSObject<MTLBaseModelProtocol> *)model error:(NSError **)error;

@end

@interface MTLBaseModel (NSObject)

// A string that describes the contents of the receiver.
//
// The default implementation is based on the receiver's class and all its
// properties for which +storageBehaviorForPropertyWithKey: returns
// MTLPropertyStoragePermanent.
+ (NSString *)descriptionFromModel:(NSObject<MTLBaseModelProtocol> *)model;

@end
