//
//  MTLBaseModel.h
//  Mantle
//
//  Created by Christian Bianciotto on 19/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "MTLModelProtocol.h"

// An abstract base class for model objects, using reflection to provide
// sensible default behaviors.
//
// The default implementations of <NSCopying>, -hash, and -isEqual: make use of
// the +propertyKeys method.
@interface MTLBaseModel : NSObject

+ (BOOL)updateModel:(id<MTLModelProtocol>)model withDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

@end

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

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

+ (NSSet *)propertyKeysFromModelClass:(Class<MTLModelProtocol>)modelClass;

+ (NSDictionary *)dictionaryValueFromModel:(id<MTLModelProtocol>)model;

@end

@interface MTLBaseModel (Merging)

+ (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModelProtocol> *)sourceModel inModel:(NSObject<MTLModelProtocol> *)destinationModel;

+ (void)mergeValuesForKeysFromModel:(NSObject<MTLModelProtocol> *)sourceModel inModel:(NSObject<MTLModelProtocol> *)destinationModel;

@end

@interface MTLBaseModel (Validation)

+ (BOOL)validateModel:(NSObject<MTLModelProtocol> *)model error:(NSError **)error;

@end

@interface MTLBaseModel (NSObject)

+ (NSString *)descriptionFromModel:(NSObject<MTLModelProtocol> *)model;

@end
