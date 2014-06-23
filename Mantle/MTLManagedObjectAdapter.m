//
//  MTLManagedObjectAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-29.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLManagedObjectAdapter.h"
#import "EXTScope.h"
#import "MTLModel.h"
#import "MTLReflection.h"
#import "NSArray+MTLManipulationAdditions.h"

NSString * const MTLManagedObjectAdapterErrorDomain = @"MTLManagedObjectAdapterErrorDomain";
const NSInteger MTLManagedObjectAdapterErrorNoClassFound = 2;
const NSInteger MTLManagedObjectAdapterErrorInitializationFailed = 3;
const NSInteger MTLManagedObjectAdapterErrorInvalidManagedObjectKey = 4;
const NSInteger MTLManagedObjectAdapterErrorUnsupportedManagedObjectPropertyType = 5;
const NSInteger MTLManagedObjectAdapterErrorUnsupportedRelationshipClass = 6;
const NSInteger MTLManagedObjectAdapterErrorUniqueFetchRequestFailed = 7;
const NSInteger MTLManagedObjectAdapterErrorInvalidManagedObjectMapping = 8;

// Performs the given block in the context's queue, if it has one.
static id performInContext(NSManagedObjectContext *context, id (^block)(void)) {
	if (context.concurrencyType == NSConfinementConcurrencyType) {
		return block();
	}

	__block id result = nil;
	[context performBlockAndWait:^{
		result = block();
	}];

	return result;
}

// Encapsulates tasks related to collecting managed object uniquing values.
@interface MTLUniquingValuesStorage : NSObject

- (void)addModel:(MTLModel *)model withUniquingValues:(NSDictionary *)uniquingValues;

- (NSArray *)modelClasses;
- (NSArray *)modelsForUniquingValues:(NSDictionary *)uniquingValues forModelClass:(Class)modelClass;
- (NSArray *)uniquingValuesForModelClass:(Class)modelClass;

@end

@implementation MTLUniquingValuesStorage {
	NSMutableDictionary *_nestedDictionariesByModelClass;
	NSMutableDictionary *_uniquingValuesByModelClass;
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;
	
	_nestedDictionariesByModelClass = [NSMutableDictionary dictionary];
	_uniquingValuesByModelClass = [NSMutableDictionary dictionary];
	
	return self;
}

- (void)addModel:(MTLModel *)model withUniquingValues:(NSDictionary *)uniquingValues {
	NSParameterAssert(model != nil);
	NSParameterAssert(uniquingValues != nil);
	
	NSArray *sortedKeys = [[uniquingValues allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *values = [uniquingValues objectsForKeys:sortedKeys notFoundMarker:NSNull.null];
	
	NSMutableDictionary *currentDictionary = [self nestedDictionaryForModelClass:model.class];
    
    for (id value in values) {
        if (value != values.lastObject) {
            NSMutableDictionary *valueDictionary = currentDictionary[value];
            if (valueDictionary == nil) {
                valueDictionary = [NSMutableDictionary dictionary];
                currentDictionary[value] = valueDictionary;
            }
            currentDictionary = valueDictionary;
        }
    }
	
	NSMutableArray *models = currentDictionary[values.lastObject];
	
	if (models == nil) {
		models = [[NSMutableArray alloc] init];
		currentDictionary[values.lastObject] = models;
		
		NSMutableArray *uniquingValuesArray = [self mutableUniquingValuesForModelClass:model.class];
		[uniquingValuesArray addObject:uniquingValues];
	}
	
	[models addObject:model];
}

- (NSArray *)modelClasses {
	NSArray *modelClassStrings = [_nestedDictionariesByModelClass allKeys];
	NSMutableArray *modelClasses = [[NSMutableArray alloc] initWithCapacity:modelClassStrings.count];
	for (NSString *modelClassString in modelClassStrings) {
		[modelClasses addObject:NSClassFromString(modelClassString)];
	}
	return [modelClasses copy];
}

- (NSArray *)modelsForUniquingValues:(NSDictionary *)uniquingValues forModelClass:(Class)modelClass {
	NSParameterAssert(uniquingValues != nil);
	NSParameterAssert(modelClass != Nil);
	
	NSArray *sortedKeys = [[uniquingValues allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *values = [uniquingValues objectsForKeys:sortedKeys notFoundMarker:NSNull.null];
    
    NSMutableDictionary *currentDictionary = [self nestedDictionaryForModelClass:modelClass];
	
    for (id value in values) {
        if (value != values.lastObject) {
            NSMutableDictionary *valueDictionary = currentDictionary[value];
            if (valueDictionary == nil) {
                return nil;
            }
            currentDictionary = valueDictionary;
        }
    }
	
	NSMutableArray *mutableModels = currentDictionary[values.lastObject];
	return [mutableModels copy];
}

- (NSArray *)uniquingValuesForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != Nil);
	
	return [[self mutableUniquingValuesForModelClass:modelClass] copy];
}

- (NSMutableDictionary *)nestedDictionaryForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != Nil);
	
	NSString *modelClassString = NSStringFromClass(modelClass);
	
	NSMutableDictionary *dictionary = _nestedDictionariesByModelClass[modelClassString];
	if (dictionary == nil) {
		dictionary = [[NSMutableDictionary alloc] init];
		_nestedDictionariesByModelClass[modelClassString] = dictionary;
	}
	
	return dictionary;
}

- (NSMutableArray *)mutableUniquingValuesForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != Nil);
	
	NSString *modelClassString = NSStringFromClass(modelClass);
	
	NSMutableArray *array = _uniquingValuesByModelClass[modelClassString];
	if (array == nil) {
		array = [[NSMutableArray alloc] init];
		_uniquingValuesByModelClass[modelClassString] = array;
	}
	
	return array;
}

@end


// Provides a bridge between MTLModels and a corresponding managed object - even
// if the latter has not been created yet.
@interface MTLManagedObjectHolder : NSObject

@property (nonatomic, strong) NSManagedObject *managedObject;

@end

@implementation MTLManagedObjectHolder

@end


@interface MTLManagedObjectAdapter ()

// The MTLModel subclass being serialized or deserialized.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +managedObjectKeysByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *managedObjectKeysByPropertyKey;

// A cached copy of the return value of +relationshipModelClassesByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *relationshipModelClassesByPropertyKey;

// Initializes the receiver to serialize or deserialize a MTLModel of the given
// class.
- (id)initWithModelClass:(Class)modelClass;

// Invoked from +modelOfClass:fromManagedObject:processedObjects:error: after
// the receiver's properties have been initialized.
- (id)modelFromManagedObject:(NSManagedObject *)managedObject processedObjects:(CFMutableDictionaryRef)processedObjects error:(NSError **)error;

// Performs the actual work of deserialization. This method is also invoked when
// processing relationships, to create a new adapter (if needed) to handle them.
//
// `processedObjects` is a dictionary mapping NSManagedObjects to the MTLModels
// that have been created so far. It should remain alive for the full process
// of deserializing the top-level managed object.
+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject processedObjects:(CFMutableDictionaryRef)processedObjects error:(NSError **)error;

// Invoked from
// +managedObjectFromModel:insertingIntoContext:processedObjects:existingObjects:error: after
// the receiver's properties have been initialized.
- (id)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context processedObjects:(CFMutableDictionaryRef)processedObjects existingObjects:(CFMutableDictionaryRef)existingObjects error:(NSError **)error;

// Performs the actual work of serialization. This method is also invoked when
// processing relationships, to create a new adapter (if needed) to handle them.
//
// `processedObjects` is a dictionary mapping MTLModels to the NSManagedObjects
// that have been created so far. It should remain alive for the full process
// of serializing the top-level MTLModel.
//
// `existingObjects` is a dictionary mapping MTLModels to MTLManagedObjectHolder
// instances according to uniquing rules. A holder may or may not contain an
// existing managed object.
+ (id)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context processedObjects:(CFMutableDictionaryRef)processedObjects existingObjects:(CFMutableDictionaryRef)existingObjects error:(NSError **)error;

// Traverses hierarchy of the given MTLModel and collects uniquing values that
// will be used to perform batch fetch requests for existing managed objects.
//
// `processedObjects` is a set of MTLModels processed so far.
+ (void)collectUniquingValuesInModelGraph:(MTLModel<MTLManagedObjectSerializing> *)model uniquingValuesStorage:(MTLUniquingValuesStorage *)uniquingValuesStorage processedObjects:(CFMutableSetRef)processedObjects context:(NSManagedObjectContext *)context;

// Returns a dictionary of managed object key and values which can be used for
// uniquing for the given MTLModel, or nil if there's no uniquing for this model
// class.
+ (NSDictionary *)uniquingValuesForModel:(MTLModel<MTLManagedObjectSerializing> *)model;

// Performs an actual fetch request for previously collected uniquing values.
//
// `managedObjectHoldersByModel` is a dictionary mapping MTLModels to
// MTLManagedObjectHolders.
+ (BOOL)fetchExistingManagedObjectsForModelClass:(Class)modelClass uniquingValuesStorage:(MTLUniquingValuesStorage *)uniquingValuesStorage managedObjectHoldersByModel:(CFMutableDictionaryRef)managedObjectHoldersByModel context:(NSManagedObjectContext *)context error:(NSError **)error;

// Looks up the NSValueTransformer that should be used for any attribute that
// corresponds the given property key and MTLModel subclass.
//
// key        - The property key to transform from or to. This argument must not
//              be nil.
// modelClass - The MTLModel subclass being serialized. This class must conform
//              to <MTLManagedObjectSerializing>. This argument must not be nil.
//
// Returns a transformer to use, or nil to not transform the property.
+ (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key forModelClass:(Class)modelClass;

// Looks up the NSValueTransformer that should be used for any attribute that
// corresponds the given property key.
//
// key - The property key to transform from or to. This argument must not be nil.
//
// Returns a transformer to use, or nil to not transform the property.
- (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key;

// Looks up the managed object keys that correspond to the property keys of the
// given MTLModel subclass. Omitted property keys are excluded.
//
// modelClass - The MTLModel subclass being serialized. This class must conform
//              to <MTLManagedObjectSerializing>. This argument must not be nil.
//
// Returns a dictionary containing property keys as keys and corresponding
// managed objects keys as values.
+ (NSDictionary *)managedObjectKeysByPropertyKeyForModelClass:(Class)modelClass;

@end

@implementation MTLManagedObjectAdapter

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ should not be initialized using -init", self.class);
	return nil;
}

- (id)initWithModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);

	self = [super init];
	if (self == nil) return nil;

	_modelClass = modelClass;
	_managedObjectKeysByPropertyKey = [self.class managedObjectKeysByPropertyKeyForModelClass:modelClass];

	if ([modelClass respondsToSelector:@selector(relationshipModelClassesByPropertyKey)]) {
		_relationshipModelClassesByPropertyKey = [[modelClass relationshipModelClassesByPropertyKey] copy];
	}

	return self;
}

#pragma mark Serialization

- (id)modelFromManagedObject:(NSManagedObject *)managedObject processedObjects:(CFMutableDictionaryRef)processedObjects error:(NSError **)error {
	NSParameterAssert(managedObject != nil);
	NSParameterAssert(processedObjects != nil);

	NSEntityDescription *entity = managedObject.entity;
	NSAssert(entity != nil, @"%@ returned a nil +entity", managedObject);

	NSManagedObjectContext *context = managedObject.managedObjectContext;

	NSDictionary *managedObjectProperties = entity.propertiesByName;
	MTLModel *model = [[self.modelClass alloc] init];

	// Pre-emptively consider this object processed, so that we don't get into
	// any cycles when processing its relationships.
	CFDictionaryAddValue(processedObjects, (__bridge void *)managedObject, (__bridge void *)model);

	BOOL (^setValueForKey)(NSString *, id) = ^(NSString *key, id value) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id replaceableValue = value;
		if (![model validateValue:&replaceableValue forKey:key error:error]) return NO;

		[model setValue:replaceableValue forKey:key];
		return YES;
	};

	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		NSString *managedObjectKey = self.managedObjectKeysByPropertyKey[propertyKey];
		if (managedObjectKey == nil) continue;

		BOOL (^deserializeAttribute)(NSAttributeDescription *) = ^(NSAttributeDescription *attributeDescription) {
			id value = performInContext(context, ^{
				return [managedObject valueForKey:managedObjectKey];
			});

			NSValueTransformer *attributeTransformer = [self entityAttributeTransformerForKey:propertyKey];
			if (attributeTransformer != nil) value = [attributeTransformer reverseTransformedValue:value];

			return setValueForKey(propertyKey, value);
		};

		BOOL (^deserializeRelationship)(NSRelationshipDescription *) = ^(NSRelationshipDescription *relationshipDescription) {
			Class nestedClass = self.relationshipModelClassesByPropertyKey[propertyKey];
			if (nestedClass == nil) {
				[NSException raise:NSInvalidArgumentException format:@"No class specified for decoding relationship at key \"%@\" in managed object %@", managedObjectKey, managedObject];
			}

			if ([relationshipDescription isToMany]) {
				id models = performInContext(context, ^ id {
					id relationshipCollection = [managedObject valueForKey:managedObjectKey];
					NSMutableArray *models = [NSMutableArray arrayWithCapacity:[relationshipCollection count]];

					for (NSManagedObject *nestedObject in relationshipCollection) {
						MTLModel *model = [self.class modelOfClass:nestedClass fromManagedObject:nestedObject processedObjects:processedObjects error:error];
						if (model == nil) return nil;
						
						[models addObject:model];
					}

					return models;
				});

				if (models == nil) return NO;
				if (![relationshipDescription isOrdered]) models = [NSSet setWithArray:models];

				return setValueForKey(propertyKey, models);
			} else {
				NSManagedObject *nestedObject = performInContext(context, ^{
					return [managedObject valueForKey:managedObjectKey];
				});

				if (nestedObject == nil) return YES;

				MTLModel *model = [self.class modelOfClass:nestedClass fromManagedObject:nestedObject processedObjects:processedObjects error:error];
				if (model == nil) return NO;

				return setValueForKey(propertyKey, model);
			}
		};

		BOOL (^deserializeProperty)(NSPropertyDescription *) = ^(NSPropertyDescription *propertyDescription) {
			if (propertyDescription == nil) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"No property by name \"%@\" exists on the entity.", @""), managedObjectKey];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not deserialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInvalidManagedObjectKey userInfo:userInfo];
				}

				return NO;
			}

			// Jump through some hoops to avoid referencing classes directly.
			NSString *propertyClassName = NSStringFromClass(propertyDescription.class);
			if ([propertyClassName isEqual:@"NSAttributeDescription"]) {
				return deserializeAttribute((id)propertyDescription);
			} else if ([propertyClassName isEqual:@"NSRelationshipDescription"]) {
				return deserializeRelationship((id)propertyDescription);
			} else {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property descriptions of class %@ are unsupported.", @""), propertyClassName];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not deserialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedManagedObjectPropertyType userInfo:userInfo];
				}

				return NO;
			}
		};

		if (!deserializeProperty(managedObjectProperties[managedObjectKey])) return nil;
	}

	return model;
}

+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject error:(NSError **)error {
	NSParameterAssert(managedObject != nil);
	
	NSArray *models = [self modelsOfClass:modelClass fromManagedObjects:@[ managedObject ] error:error];
	return models.mtl_firstObject;
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromManagedObjects:(NSArray *)managedObjects error:(NSError **)error {
	NSSet *propertyKeys = [modelClass propertyKeys];

	for (NSString *mappedPropertyKey in [modelClass managedObjectKeysByPropertyKey]) {
		if ([propertyKeys containsObject:mappedPropertyKey]) continue;

		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid entity attribute mapping", nil),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%1$@ could not be parsed because its entity attribute mapping contains illegal property keys.", nil), modelClass]
			};

			*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInvalidManagedObjectMapping userInfo:userInfo];
		}

		return nil;
	}

	CFMutableDictionaryRef processedObjects = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	if (processedObjects == NULL) return nil;

	@onExit {
		CFRelease(processedObjects);
	};
	
	NSMutableArray *models = [[NSMutableArray alloc] initWithCapacity:managedObjects.count];
	
	for (NSManagedObject *managedObject in managedObjects) {
		id model = [self modelOfClass:modelClass fromManagedObject:managedObject processedObjects:processedObjects error:error];
		
		if (model == nil) return nil;
		
		[models addObject:model];
	}
	
	return models;
}

+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject processedObjects:(CFMutableDictionaryRef)processedObjects error:(NSError **)error {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert(processedObjects != nil);

	if (managedObject == nil) return nil;

	const void *existingModel = CFDictionaryGetValue(processedObjects, (__bridge void *)managedObject);
	if (existingModel != NULL) {
		return (__bridge id)existingModel;
	}

	if ([modelClass respondsToSelector:@selector(classForDeserializingManagedObject:)]) {
		modelClass = [modelClass classForDeserializingManagedObject:managedObject];
		if (modelClass == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not deserialize managed object", @""),
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to deserialize the object.", @"")
				};

				*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorNoClassFound userInfo:userInfo];
			}

			return nil;
		}
	}

	MTLManagedObjectAdapter *adapter = [[self alloc] initWithModelClass:modelClass];
	return [adapter modelFromManagedObject:managedObject processedObjects:processedObjects error:error];
}

- (id)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context processedObjects:(CFMutableDictionaryRef)processedObjects existingObjects:(CFMutableDictionaryRef)existingObjects error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert(context != nil);
	NSParameterAssert(processedObjects != nil);
	NSParameterAssert(existingObjects != nil);

	NSString *entityName = [model.class managedObjectEntityName];
	NSAssert(entityName != nil, @"%@ returned a nil +managedObjectEntityName", model.class);

	Class entityDescriptionClass = NSClassFromString(@"NSEntityDescription");
	NSAssert(entityDescriptionClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");

	// Check if we already have a corresponding existing managed object.
    MTLManagedObjectHolder *managedObjectHolder = (__bridge MTLManagedObjectHolder *)CFDictionaryGetValue(existingObjects, (__bridge void *)model);
	__block NSManagedObject *managedObject = managedObjectHolder.managedObject;

	if (managedObject == nil) {
		managedObject = [entityDescriptionClass insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
	} else {
		// Our CoreData store already has data for this model, we need to merge
		[self mergeValuesOfModel:model forKeysFromManagedObject:managedObject];
	}

	if (managedObject == nil) {
		if (error != NULL) {
			NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Failed to initialize a managed object from entity named \"%@\".", @""), entityName];

			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
				NSLocalizedFailureReasonErrorKey: failureReason,
			};

			*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInitializationFailed userInfo:userInfo];
		}

		return nil;
	}

	// Assign all errors to this variable to work around a memory problem.
	//
	// See https://github.com/github/Mantle/pull/120 for more context.
	__block NSError *tmpError;

	// Pre-emptively consider this object processed, so that we don't get into
	// any cycles when processing its relationships.
	CFDictionaryAddValue(processedObjects, (__bridge void *)model, (__bridge void *)managedObject);
    
    managedObjectHolder.managedObject = managedObject;

	NSDictionary *dictionaryValue = model.dictionaryValue;
	NSDictionary *managedObjectProperties = managedObject.entity.propertiesByName;

	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		NSString *managedObjectKey = self.managedObjectKeysByPropertyKey[propertyKey];
		if (managedObjectKey == nil) return;
		if ([value isEqual:NSNull.null]) value = nil;

		BOOL (^serializeAttribute)(NSAttributeDescription *) = ^(NSAttributeDescription *attributeDescription) {
			// Mark this as being autoreleased, because validateValue may return
			// a new object to be stored in this variable (and we don't want ARC to
			// double-free or leak the old or new values).
			__autoreleasing id transformedValue = value;

			NSValueTransformer *attributeTransformer = [self entityAttributeTransformerForKey:propertyKey];
			if (attributeTransformer != nil) transformedValue = [attributeTransformer transformedValue:transformedValue];

			if (![managedObject validateValue:&transformedValue forKey:managedObjectKey error:&tmpError]) return NO;
			[managedObject setValue:transformedValue forKey:managedObjectKey];

			return YES;
		};

		NSManagedObject * (^objectForRelationshipFromModel)(id) = ^ id (id model) {
			if (![model isKindOfClass:MTLModel.class] || ![model conformsToProtocol:@protocol(MTLManagedObjectSerializing)]) {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property of class %@ cannot be encoded into an NSManagedObject.", @""), [model class]];

				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
					NSLocalizedFailureReasonErrorKey: failureReason
				};

				tmpError = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedRelationshipClass userInfo:userInfo];

				return nil;
			}

			return [self.class managedObjectFromModel:model insertingIntoContext:context processedObjects:processedObjects existingObjects:existingObjects error:&tmpError];
		};

		BOOL (^serializeRelationship)(NSRelationshipDescription *) = ^(NSRelationshipDescription *relationshipDescription) {
			if (value == nil) return YES;

			if ([relationshipDescription isToMany]) {
				if (![value conformsToProtocol:@protocol(NSFastEnumeration)]) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property of class %@ cannot be encoded into a to-many relationship.", @""), [value class]];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason
					};

					tmpError = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedRelationshipClass userInfo:userInfo];

					return NO;
				}

				id relationshipCollection;
				if ([relationshipDescription isOrdered]) {
					relationshipCollection = [NSMutableOrderedSet orderedSet];
				} else {
					relationshipCollection = [NSMutableSet set];
				}

				for (MTLModel *model in value) {
					NSManagedObject *nestedObject = objectForRelationshipFromModel(model);
					if (nestedObject == nil) return NO;

					[relationshipCollection addObject:nestedObject];
				}

				[managedObject setValue:relationshipCollection forKey:managedObjectKey];
			} else {
				NSManagedObject *nestedObject = objectForRelationshipFromModel(value);
				if (nestedObject == nil) return NO;

				[managedObject setValue:nestedObject forKey:managedObjectKey];
			}

			return YES;
		};

		BOOL (^serializeProperty)(NSPropertyDescription *) = ^(NSPropertyDescription *propertyDescription) {
			if (propertyDescription == nil) {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"No property by name \"%@\" exists on the entity.", @""), managedObjectKey];

				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
					NSLocalizedFailureReasonErrorKey: failureReason
				};

				tmpError = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInvalidManagedObjectKey userInfo:userInfo];

				return NO;
			}

			// Jump through some hoops to avoid referencing classes directly.
			NSString *propertyClassName = NSStringFromClass(propertyDescription.class);
			if ([propertyClassName isEqual:@"NSAttributeDescription"]) {
				return serializeAttribute((id)propertyDescription);
			} else if ([propertyClassName isEqual:@"NSRelationshipDescription"]) {
				return serializeRelationship((id)propertyDescription);
			} else {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property descriptions of class %@ are unsupported.", @""), propertyClassName];

				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
					NSLocalizedFailureReasonErrorKey: failureReason
				};

				tmpError = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedManagedObjectPropertyType userInfo:userInfo];

				return NO;
			}
		};
		
		if (!serializeProperty(managedObjectProperties[managedObjectKey])) {
			performInContext(context, ^ id {
				[context deleteObject:managedObject];
				return nil;
			});

			managedObject = nil;
			*stop = YES;
		}
	}];

	if (managedObject != nil && ![managedObject validateForInsert:&tmpError]) {
		managedObject = performInContext(context, ^ id {
			[context deleteObject:managedObject];
			return nil;
		});
	}

	if (error != NULL) {
		*error = tmpError;
	}

	return managedObject;
}

+ (id)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSParameterAssert(model != nil);
	
	NSArray *managedObjects = [self managedObjectsFromModels:@[ model ] insertingIntoContext:context error:error];
	return managedObjects.mtl_firstObject;
}

+ (NSArray *)managedObjectsFromModels:(NSArray *)models insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error {
	MTLUniquingValuesStorage *uniquingValuesStorage = [[MTLUniquingValuesStorage alloc] init];
	
    // Compare MTLModel keys using pointer equality, not -isEqual:.
	CFSetCallBacks setCallbacks = kCFTypeSetCallBacks;
	setCallbacks.equal = NULL;
    
    CFDictionaryKeyCallBacks keyCallbacks = kCFTypeDictionaryKeyCallBacks;
	keyCallbacks.equal = NULL;

	
	CFMutableSetRef processedObjectsSet = CFSetCreateMutable(NULL, 0, &setCallbacks);
	@onExit {
		CFRelease(processedObjectsSet);
	};
	
	for (MTLModel<MTLManagedObjectSerializing> *model in models) {
		[self collectUniquingValuesInModelGraph:model uniquingValuesStorage:uniquingValuesStorage processedObjects:processedObjectsSet context:context];
	}
	
	CFMutableDictionaryRef existingObjects = CFDictionaryCreateMutable(NULL, 0, &keyCallbacks, &kCFTypeDictionaryValueCallBacks);
	@onExit {
		CFRelease(existingObjects);
	};
	
	for (Class modelClass in [uniquingValuesStorage modelClasses]) {
		BOOL success = [self fetchExistingManagedObjectsForModelClass:modelClass uniquingValuesStorage:uniquingValuesStorage managedObjectHoldersByModel:existingObjects context:context error:error];
		
		if (!success) return nil;
	}
	
	CFMutableDictionaryRef processedObjects = CFDictionaryCreateMutable(NULL, 0, &keyCallbacks, &kCFTypeDictionaryValueCallBacks);
	@onExit {
		CFRelease(processedObjects);
	};
	
	NSMutableArray *managedObjects = [[NSMutableArray alloc] initWithCapacity:models.count];
	
	for (MTLModel<MTLManagedObjectSerializing> *model in models) {
		id managedObject = [self managedObjectFromModel:model insertingIntoContext:context processedObjects:processedObjects existingObjects:existingObjects error:error];
		
		if (managedObject == nil) return nil;
		
		[managedObjects addObject:managedObject];
	}
	
	return managedObjects;
}

+ (id)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context processedObjects:(CFMutableDictionaryRef)processedObjects existingObjects:(CFMutableDictionaryRef)existingObjects error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert(context != nil);
	NSParameterAssert(processedObjects != nil);
	NSParameterAssert(existingObjects != nil);

	const void *existingManagedObject = CFDictionaryGetValue(processedObjects, (__bridge void *)model);
	if (existingManagedObject != NULL) {
		return (__bridge id)existingManagedObject;
	}

	MTLManagedObjectAdapter *adapter = [[self alloc] initWithModelClass:model.class];
	return [adapter managedObjectFromModel:model insertingIntoContext:context processedObjects:processedObjects existingObjects:existingObjects error:error];
}

+ (void)collectUniquingValuesInModelGraph:(MTLModel<MTLManagedObjectSerializing> *)model uniquingValuesStorage:(MTLUniquingValuesStorage *)uniquingValuesStorage processedObjects:(CFMutableSetRef)processedObjects context:(NSManagedObjectContext *)context {
	NSParameterAssert(model != nil);
	NSParameterAssert(uniquingValuesStorage != nil);
	NSParameterAssert(context != nil);
	
	if (CFSetContainsValue(processedObjects, (__bridge void *)model)) return;
	CFSetAddValue(processedObjects, (__bridge void *)model);
		
    NSDictionary *uniquingValues = [self uniquingValuesForModel:model];
	if (uniquingValues != nil) {
		[uniquingValuesStorage addModel:model withUniquingValues:uniquingValues];
	}

	Class entityDescriptionClass = NSClassFromString(@"NSEntityDescription");
	NSAssert(entityDescriptionClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");
	
	NSString *entityName = [model.class managedObjectEntityName];
	
	NSEntityDescription *entityDescription = [entityDescriptionClass entityForName:entityName inManagedObjectContext:context];
	NSDictionary *relationships = entityDescription.relationshipsByName;
	NSDictionary *managedObjectKeysByPropertyKey = [self managedObjectKeysByPropertyKeyForModelClass:model.class];
	
	NSDictionary *dictionaryValue = model.dictionaryValue;
	
	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		if (value == NSNull.null) return;
		
		NSString *managedObjectKey = managedObjectKeysByPropertyKey[propertyKey];
		if (managedObjectKey == nil) return;
		
		NSRelationshipDescription *relationship = relationships[managedObjectKey];
		if (!relationship) return;
		
		if ([relationship isToMany]) {
			for (id child in value) {
				[self collectUniquingValuesInModelGraph:child uniquingValuesStorage:uniquingValuesStorage processedObjects:processedObjects context:context];
			}
		} else {
			[self collectUniquingValuesInModelGraph:value uniquingValuesStorage:uniquingValuesStorage processedObjects:processedObjects context:context];
		}
	}];
}

+ (NSDictionary *)uniquingValuesForModel:(MTLModel<MTLManagedObjectSerializing> *)model {
	NSParameterAssert(model != nil);
	if (![model.class respondsToSelector:@selector(propertyKeysForManagedObjectUniquing)]) return nil;
	
	NSSet *propertyKeys = [model.class propertyKeysForManagedObjectUniquing];
	if (propertyKeys == nil) return nil;
	
	NSAssert(propertyKeys.count > 0, @"+propertyKeysForManagedObjectUniquing must not be empty.");
	
	NSDictionary *managedObjectKeysByPropertyKey = [self managedObjectKeysByPropertyKeyForModelClass:model.class];
	
	NSMutableDictionary *uniquingValues = [NSMutableDictionary dictionaryWithCapacity:propertyKeys.count];
	
	for (NSString *propertyKey in propertyKeys) {
		id value = [model valueForKeyPath:propertyKey];
		
		NSString *managedObjectKey = managedObjectKeysByPropertyKey[propertyKey];
		NSAssert(managedObjectKey != nil, @"%@ must map to a managed object key.", propertyKey);
		
		NSValueTransformer *attributeTransformer = [self entityAttributeTransformerForKey:propertyKey forModelClass:model.class];
		if (attributeTransformer != nil) value = [attributeTransformer transformedValue:value];
		
		uniquingValues[managedObjectKey] = value ?: NSNull.null;
	}
	
	return [uniquingValues copy];
}

+ (BOOL)fetchExistingManagedObjectsForModelClass:(Class)modelClass uniquingValuesStorage:(MTLUniquingValuesStorage *)uniquingValuesStorage managedObjectHoldersByModel:(CFMutableDictionaryRef)managedObjectHoldersByModel context:(NSManagedObjectContext *)context error:(NSError **)error {
	NSParameterAssert(modelClass != Nil);
	NSParameterAssert(uniquingValuesStorage != nil);
	NSParameterAssert(managedObjectHoldersByModel != nil);
	NSParameterAssert(context != nil);
	
	NSSet *propertyKeys = [modelClass propertyKeysForManagedObjectUniquing];
	NSDictionary *managedObjectKeysByPropertyKey = [self managedObjectKeysByPropertyKeyForModelClass:modelClass];
	NSArray *managedObjectKeys = [managedObjectKeysByPropertyKey objectsForKeys:[propertyKeys allObjects] notFoundMarker:NSNull.null];
    
    NSArray *uniquingValuesArray = [uniquingValuesStorage uniquingValuesForModelClass:modelClass];
	
	NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:propertyKeys.count];
	
	for (NSString *managedObjectKey in managedObjectKeys) {
        NSMutableArray *managedObjectValues = [NSMutableArray arrayWithCapacity:uniquingValuesArray.count];
        
        for (NSDictionary *uniquingValues in uniquingValuesArray) {
            [managedObjectValues addObject:uniquingValues[managedObjectKey]];
        }
        
        NSPredicate *subpredicate = [NSPredicate predicateWithFormat:@"%K in %@", managedObjectKey, [NSSet setWithArray:managedObjectValues]];
        [subpredicates addObject:subpredicate];
    }
    
    NSPredicate *uniquingPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];

    
	NSString *entityName = [modelClass managedObjectEntityName];
	NSAssert(entityName != nil, @"%@ returned a nil +managedObjectEntityName", modelClass);
	
	Class entityDescriptionClass = NSClassFromString(@"NSEntityDescription");
	NSAssert(entityDescriptionClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");
	
	Class fetchRequestClass = NSClassFromString(@"NSFetchRequest");
	NSAssert(fetchRequestClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");
	
	__block NSError *fetchRequestError = nil;
	__block BOOL encounteredError = NO;
	NSArray *managedObjects = performInContext(context, ^ id {
		NSFetchRequest *fetchRequest = [[fetchRequestClass alloc] init];
		fetchRequest.entity = [entityDescriptionClass entityForName:entityName inManagedObjectContext:context];
		fetchRequest.predicate = uniquingPredicate;
		fetchRequest.returnsObjectsAsFaults = NO;
		
		NSArray *results = [context executeFetchRequest:fetchRequest error:&fetchRequestError];
		
		if (results == nil) {
			encounteredError = YES;
			if (error != NULL) {
				NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Failed to fetch a managed object for uniqing predicate \"%@\".", @""), uniquingPredicate];
				
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
					NSLocalizedFailureReasonErrorKey: failureReason,
				};
				
				fetchRequestError = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUniqueFetchRequestFailed userInfo:userInfo];
			}
			
			return nil;
		}
		
		return results;
	});
	
	if (encounteredError && error != NULL) {
		*error = fetchRequestError;
		return NO;
	}
    
    
    for (NSDictionary *uniquingValues in uniquingValuesArray) {
        MTLManagedObjectHolder *managedObjectHolder = [[MTLManagedObjectHolder alloc] init];
		NSArray *models = [uniquingValuesStorage modelsForUniquingValues:uniquingValues forModelClass:modelClass];
        for (id model in models) {
            CFDictionarySetValue(managedObjectHoldersByModel, (__bridge void *)model, (__bridge void *)managedObjectHolder);
        }
    }
    
	for (NSManagedObject *managedObject in managedObjects) {
        NSMutableDictionary *uniquingValues = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
		
		for (NSString *propertyKey in propertyKeys) {
			NSString *managedObjectKey = managedObjectKeysByPropertyKey[propertyKey];
			
			id value = [managedObject valueForKey:managedObjectKey];
			if (value == nil) value = NSNull.null;
			
			uniquingValues[managedObjectKey] = value;
		}
        
        NSArray *models = [uniquingValuesStorage modelsForUniquingValues:uniquingValues forModelClass:modelClass];
        
        if (models != nil) {
            MTLManagedObjectHolder *managedObjectHolder = (__bridge MTLManagedObjectHolder *)CFDictionaryGetValue(managedObjectHoldersByModel, (__bridge void *)models.mtl_firstObject);
            managedObjectHolder.managedObject = managedObject;
        }
	}

	return YES;
}

+ (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key forModelClass:(Class)modelClass {
	NSParameterAssert(key != nil);
	NSParameterAssert(modelClass != Nil);
	
	SEL selector = MTLSelectorWithKeyPattern(key, "EntityAttributeTransformer");
	if ([modelClass respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[modelClass methodSignatureForSelector:selector]];
		invocation.target = modelClass;
		invocation.selector = selector;
		[invocation invoke];
		
		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}
	
	if ([modelClass respondsToSelector:@selector(entityAttributeTransformerForKey:)]) {
		return [modelClass entityAttributeTransformerForKey:key];
	}
	
	return nil;
}

- (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key {
	return [self.class entityAttributeTransformerForKey:key forModelClass:self.modelClass];
}

+ (NSDictionary *)managedObjectKeysByPropertyKeyForModelClass:(Class)modelClass {
	NSSet *propertyKeys = [modelClass propertyKeys];
	NSDictionary *managedObjectKeysByPropertyKey = [modelClass managedObjectKeysByPropertyKey];
	
	NSMutableDictionary *filteredKeys = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
	
	for (NSString *key in propertyKeys) {
		id managedObjectKey = managedObjectKeysByPropertyKey[key];
		
		if ([managedObjectKey isEqual:NSNull.null]) continue;
		
		filteredKeys[key] = managedObjectKey ?: key;
	}
	
	return [filteredKeys copy];
}

- (void)mergeValueOfModel:(MTLModel<MTLManagedObjectSerializing> *)model forKey:(NSString *)key fromManagedObject:(NSManagedObject *)managedObject {
	[model mergeValueForKey:key fromManagedObject:managedObject];
}

- (void)mergeValuesOfModel:(MTLModel<MTLManagedObjectSerializing> *)model forKeysFromManagedObject:(NSManagedObject *)managedObject {
	if ([model respondsToSelector:@selector(mergeValuesForKeysFromManagedObject:)]) {
		[model mergeValuesForKeysFromManagedObject:managedObject];
	} else if ([model respondsToSelector:@selector(mergeValueForKey:fromManagedObject:)]) {
		[[model.class managedObjectKeysByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *managedObjectKey, BOOL *stop) {
			[self mergeValueOfModel:model forKey:key fromManagedObject:managedObject];
		}];
	}
}

@end