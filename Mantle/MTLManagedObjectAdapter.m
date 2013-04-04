//
//  MTLManagedObjectAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-29.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLManagedObjectAdapter.h"
#import "MTLModel.h"
#import "MTLReflection.h"

NSString * const MTLManagedObjectAdapterErrorDomain = @"MTLManagedObjectAdapterErrorDomain";
const NSInteger MTLManagedObjectAdapterErrorNoClassFound = 2;
const NSInteger MTLManagedObjectAdapterErrorInitializationFailed = 3;
const NSInteger MTLManagedObjectAdapterErrorInvalidManagedObjectKey = 4;
const NSInteger MTLManagedObjectAdapterErrorUnsupportedManagedObjectPropertyType = 5;
const NSInteger MTLManagedObjectAdapterErrorUnsupportedRelationshipClass = 6;

// An exception was thrown and caught.
static const NSInteger MTLManagedObjectAdapterErrorExceptionThrown = 1;

@interface MTLManagedObjectAdapter ()

// The MTLModel subclass being serialized or deserialized.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +managedObjectKeysByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *managedObjectKeysByPropertyKey;

// A cached copy of the return value of +relationshipModelClassesByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *relationshipModelClassesByPropertyKey;

// Looks up the NSValueTransformer that should be used for any attribute that
// corresponds the given property key.
//
// key - The property key to transform from or to. This argument must not be nil.
//
// Returns a transformer to use, or nil to not transform the property.
- (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key;

// Looks up the managed object key that corresponds to the given key.
//
// key - The property key to retrieve the corresponding managed object key for.
//       This argument must not be nil.
//
// Returns a key to use, or nil to omit the property from managed object
// serialization.
- (NSString *)managedObjectKeyForKey:(NSString *)key;

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
	_managedObjectKeysByPropertyKey = [[modelClass managedObjectKeysByPropertyKey] copy];

	if ([modelClass respondsToSelector:@selector(relationshipModelClassesByPropertyKey)]) {
		_relationshipModelClassesByPropertyKey = [[modelClass relationshipModelClassesByPropertyKey] copy];
	}

	return self;
}

#pragma mark Serialization

+ (id)modelOfClass:(Class)modelClass fromManagedObject:(NSManagedObject *)managedObject error:(NSError **)error {
	Class managedObjectClass = NSClassFromString(@"NSManagedObject");
	NSAssert(managedObjectClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");

	return nil;
}

- (NSManagedObject *)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert(context != nil);

	NSEntityDescription *entity = [model.class managedObjectEntity];
	NSAssert(entity != nil, @"%@ returned a nil +managedObjectEntity", model.class);

	if (context != nil) {
		NSAssert([context.persistentStoreCoordinator.managedObjectModel isEqual:entity.managedObjectModel], @"The managed object model of %@ does not match that of %@", context, entity);
	}

	Class managedObjectClass = NSClassFromString(@"NSManagedObject");
	NSAssert(managedObjectClass != nil, @"CoreData.framework must be linked to use MTLManagedObjectAdapter");

	__block NSManagedObject *managedObject = [[managedObjectClass alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
	if (managedObject == nil) {
		if (error != NULL) {
			NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Failed to initialize a managed object from entity named \"%@\".", @""), entity.name];

			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
				NSLocalizedFailureReasonErrorKey: failureReason,
			};

			*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInitializationFailed userInfo:userInfo];
		}

		return nil;
	}

	NSDictionary *dictionaryValue = model.dictionaryValue;
	NSDictionary *managedObjectProperties = entity.propertiesByName;

	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		NSString *managedObjectKey = [self managedObjectKeyForKey:propertyKey];
		if (managedObjectKey == nil) return;
		if ([value isEqual:NSNull.null]) value = nil;

		BOOL (^serializeAttribute)(NSAttributeDescription *) = ^(NSAttributeDescription *attributeDescription) {
			// Mark this as being autoreleased, because validateValue may return
			// a new object to be stored in this variable (and we don't want ARC to
			// double-free or leak the old or new values).
			__autoreleasing id transformedValue = value;

			NSValueTransformer *attributeTransformer = [self entityAttributeTransformerForKey:propertyKey];
			if (attributeTransformer != nil) transformedValue = [attributeTransformer transformedValue:transformedValue];

			if (![managedObject validateValue:&transformedValue forKey:managedObjectKey error:error]) return NO;
			[managedObject setValue:transformedValue forKey:managedObjectKey];

			return YES;
		};

		BOOL (^serializeRelationship)(NSRelationshipDescription *) = ^(NSRelationshipDescription *relationshipDescription) {
			if (value == nil) return YES;

			// TODO: Handle collections.
			if (![value isKindOfClass:MTLModel.class] || ![value conformsToProtocol:@protocol(MTLManagedObjectSerializing)]) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property of class %@ cannot be encoded into a relationship.", @""), [value class]];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedRelationshipClass userInfo:userInfo];
				}

				return NO;
			}

			NSManagedObject *nestedObject = [self managedObjectFromModel:value insertingIntoContext:context error:error];
			if (nestedObject == nil) return NO;

			void (^deleteNestedObject)(void) = ^{
				[context performBlockAndWait:^{
					[context deleteObject:nestedObject];
				}];
			};

			// Mark this as being autoreleased, because validateValue may return
			// a new object to be stored in this variable (and we don't want ARC to
			// double-free or leak the old or new values).
			__autoreleasing NSManagedObject *validatedObject = nestedObject;
			if (![managedObject validateValue:&validatedObject forKey:managedObjectKey error:error]) {
				deleteNestedObject();
				return NO;
			}

			if (validatedObject != nestedObject) {
				deleteNestedObject();

				nestedObject = validatedObject;
				if (context != nil) {
					if (![nestedObject validateForInsert:error]) return NO;

					[context performBlockAndWait:^{
						[context insertObject:nestedObject];
					}];
				}
			}

			return YES;
		};

		BOOL (^serializeProperty)(NSPropertyDescription *) = ^(NSPropertyDescription *propertyDescription) {
			if (propertyDescription == nil) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"No property by name \"%@\" exists on the entity.", @""), managedObjectKey];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorInvalidManagedObjectKey userInfo:userInfo];
				}

				return NO;
			}

			// Jump through some hoops to avoid referencing classes directly.
			NSString *propertyClassName = NSStringFromClass(propertyDescription.class);
			if ([propertyClassName isEqual:@"NSAttributeDescription"]) {
				return serializeAttribute((id)propertyDescription);
			} else if ([propertyClassName isEqual:@"NSRelationshipDescription"]) {
				return serializeRelationship((id)propertyDescription);
			} else {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Property descriptions of class %@ are unsupported.", @""), propertyClassName];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not serialize managed object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLManagedObjectAdapterErrorDomain code:MTLManagedObjectAdapterErrorUnsupportedManagedObjectPropertyType userInfo:userInfo];
				}

				return NO;
			}
		};
		
		if (!serializeProperty(managedObjectProperties[managedObjectKey])) {
			managedObject = nil;
			*stop = YES;
		}
	}];

	if (context != nil) {
		if (![managedObject validateForInsert:error]) return nil;

		[context performBlockAndWait:^{
			[context insertObject:managedObject];
		}];
	}

	return managedObject;
}

+ (NSManagedObject *)managedObjectFromModel:(MTLModel<MTLManagedObjectSerializing> *)model insertingIntoContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSParameterAssert(model != nil);

	MTLManagedObjectAdapter *adapter = [[self alloc] initWithModelClass:model.class];
	return [adapter managedObjectFromModel:model insertingIntoContext:context error:error];
}

- (NSValueTransformer *)entityAttributeTransformerForKey:(NSString *)key {
	NSParameterAssert(key != nil);

	SEL selector = MTLSelectorWithKeyPattern(key, "EntityAttributeTransformer");
	if ([self.modelClass respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.modelClass methodSignatureForSelector:selector]];
		invocation.target = self.modelClass;
		invocation.selector = selector;
		[invocation invoke];

		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}

	if ([self.modelClass respondsToSelector:@selector(entityAttributeTransformerForKey:)]) {
		return [self.modelClass entityAttributeTransformerForKey:key];
	}

	return nil;
}

- (NSString *)managedObjectKeyForKey:(NSString *)key {
	NSParameterAssert(key != nil);

	id managedObjectKey = self.managedObjectKeysByPropertyKey[key];
	if ([managedObjectKey isEqual:NSNull.null]) return nil;

	if (managedObjectKey == nil) {
		return key;
	} else {
		return managedObjectKey;
	}
}

@end
