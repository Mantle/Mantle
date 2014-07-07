//
//  MTLJSONAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "NSDictionary+MTLJSONKeyPath.h"

#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLTransformerErrorHandling.h"
#import "MTLReflection.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

NSString * const MTLJSONAdapterErrorDomain = @"MTLJSONAdapterErrorDomain";
const NSInteger MTLJSONAdapterErrorNoClassFound = 2;
const NSInteger MTLJSONAdapterErrorClassFoundOnUpdate = 5;
const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary = 3;
const NSInteger MTLJSONAdapterErrorInvalidJSONMapping = 4;

// An exception was thrown and caught.
const NSInteger MTLJSONAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MTLJSONAdapterThrownExceptionErrorKey = @"MTLJSONAdapterThrownException";

@interface MTLJSONAdapter ()

// The MTLBaseModelProtocol implementation being parsed, or the class of `model` if parsing has
// completed.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +JSONKeyPathsByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;

// A cached copy of the return value of -valueTransformersForModelClass:
@property (nonatomic, copy, readonly) NSDictionary *valueTransformersByPropertyKey;

// Used to cache the JSON adapters returned by -JSONAdapterForModelClass:error:.
@property (nonatomic, strong, readonly) NSMapTable *JSONAdaptersByModelClass;

// If +classForParsingJSONDictionary: returns a model class different from the
// one this adapter was initialized with, use this method to obtain a cached
// instance of a suitable adapter instead.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
// error -      If not NULL, this may be set to an error that occurs during
//              initializing the adapter.
//
// Returns a JSON adapter for modelClass, creating one of necessary. If no
// adapter could be created, nil is returned.
- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error;

// Collect all value transformers needed for a given class.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
//
// Returns a dictionary with the properties of modelClass that need
// transformation as keys and the value transformers as values.
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

@end

@implementation MTLJSONAdapter

//#pragma mark Check parameters
//
//- (BOOL)checkJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error {
//	NSParameterAssert(modelClass != nil);
//	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLBaseModelProtocol)]);
//	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
//	
//	if (JSONDictionary == nil || ![JSONDictionary isKindOfClass:NSDictionary.class]) {
//		if (error != NULL) {
//			NSDictionary *userInfo = @{
//									   NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON dictionary", @""),
//									   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created or update because an invalid JSON dictionary was provided: %@", @""), NSStringFromClass(modelClass), JSONDictionary.class],
//									   };
//			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
//		}
//		return NO;
//	}
//	
//	return YES;
//}
//
//- (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary fromModelClass:(Class)modelClass error:(NSError **)error {
//	if ([modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
//		modelClass = [modelClass classForParsingJSONDictionary:JSONDictionary];
//		if (modelClass == nil) {
//			if (error != NULL) {
//				NSDictionary *userInfo = @{
//										   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
//										   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
//										   };
//				
//				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorNoClassFound userInfo:userInfo];
//			}
//			
//			return nil;
//		}
//		
//		NSAssert([modelClass conformsToProtocol:@protocol(MTLBaseModelProtocol)], @"Class %@ returned from +classForParsingJSONDictionary: is not a conform to <MTLBaseModelProtocol>", modelClass);
//		NSAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MTLJSONSerializing>", modelClass);
//	}
//	
//	return modelClass;
//}

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithModelClass:modelClass];
	
	return [adapter modelFromJSONDictionary:JSONDictionary error:error];
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error {
	if (JSONArray == nil || ![JSONArray isKindOfClass:NSArray.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
									   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON array was provided: %@", @""), NSStringFromClass(modelClass), JSONArray.class],
									   };
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}
	
	NSMutableArray *models = [NSMutableArray arrayWithCapacity:JSONArray.count];
	for (NSDictionary *JSONDictionary in JSONArray){
		id <MTLBaseModelProtocol>model = [self modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
		
		if (model == nil) return nil;
		
		[models addObject:model];
	}
	
	return models;
}

+ (BOOL)updateModel:(id<MTLJSONSerializing>)model fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	NSError *tempError = nil;
	MTLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];
	
	BOOL update = [adapter updateModel:model fromJSONDictionary:JSONDictionary error:&tempError];
	
	if(error != NULL) *error = tempError;
	
	return update && tempError == nil && adapter != nil;
}

+ (BOOL)upadeModels:(NSArray *)models fromJSONArray:(NSArray *)JSONArray error:(NSError **)error {
	NSParameterAssert(models != nil);
	NSParameterAssert([models isKindOfClass:NSArray.class]);
	
	if (JSONArray == nil || ![JSONArray isKindOfClass:NSArray.class] || JSONArray.count != models.count) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
									   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Models could not be update because an invalid JSON array was provided: %@", @""), JSONArray.class],
									   };
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return NO;
	}
	
	BOOL update = YES;
	for(NSUInteger i=0; i<JSONArray.count; i++){
		NSDictionary *JSONDictionary = [JSONArray objectAtIndex:i];
		id <MTLJSONSerializing> model = [models objectAtIndex:i];
		
		update &= [self updateModel:model fromJSONDictionary:JSONDictionary error:error];
	}
	
	return update;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];
	
	return [adapter JSONDictionaryFromModel:model error:error];
}

+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError **)error {
	NSParameterAssert(models != nil);
	NSParameterAssert([models isKindOfClass:NSArray.class]);
	
	NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:models.count];
	for (id <MTLJSONSerializing> model in models) {
		NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model error:error];
		if (JSONDictionary == nil) return nil;
		
		[JSONArray addObject:JSONDictionary];
	}
	
	return JSONArray;
}

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ must be initialized with a model class", self.class);
	return nil;
}

- (id)initWithModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	self = [super init];
	if (self == nil) return nil;
	
	_modelClass = modelClass;
	
	_JSONKeyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];
	
	NSSet *propertyKeys = [self.modelClass propertyKeys];
	
	for (NSString *mappedPropertyKey in _JSONKeyPathsByPropertyKey) {
		if (![propertyKeys containsObject:mappedPropertyKey]) {
			NSAssert(NO, @"%@ is not a property of %@.", mappedPropertyKey, modelClass);
			return nil;
		}
		
		id value = _JSONKeyPathsByPropertyKey[mappedPropertyKey];
		
		if ([value isKindOfClass:NSArray.class]) {
			for (NSString *keyPath in value) {
				if ([keyPath isKindOfClass:NSString.class]) continue;
				
				NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.", mappedPropertyKey, value);
				return nil;
			}
		} else if (![value isKindOfClass:NSString.class]) {
			NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.",mappedPropertyKey, value);
			return nil;
		}
	}
	
	_valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];
	
	_JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];
	
	return self;
}


#pragma mark Serialization

- (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert([model isKindOfClass:self.modelClass]);
	
	if (self.modelClass != model.class) {
		MTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:model.class error:error];
		
		return [otherAdapter JSONDictionaryFromModel:model error:error];
	}
	
	NSSet *propertyKeysToSerialize = [self serializablePropertyKeys:[NSSet setWithArray:self.JSONKeyPathsByPropertyKey.allKeys] forModel:model];
	
	NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize.allObjects];
	NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
	
	__block BOOL success = YES;
	__block NSError *tmpError = nil;
	
	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
		
		if (JSONKeyPaths == nil) return;
		
		NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionaryValue we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;
			
			if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
				id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
				
				value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];
				
				if (!success) {
					*stop = YES;
					return;
				}
			} else {
				value = [transformer reverseTransformedValue:value] ?: NSNull.null;
			}
		}
		
		void (^createComponents)(id, NSString *) = ^(id obj, NSString *keyPath) {
			NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
			
			// Set up dictionaries at each step of the key path.
			for (NSString *component in keyPathComponents) {
				if ([obj valueForKey:component] == nil) {
					// Insert an empty mutable dictionary at this spot so that we
					// can set the whole key path afterward.
					[obj setValue:[NSMutableDictionary dictionary] forKey:component];
				}
				
				obj = [obj valueForKey:component];
			}
		};
		
		if ([JSONKeyPaths isKindOfClass:NSString.class]) {
			createComponents(JSONDictionary, JSONKeyPaths);
			
			[JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
		}
		
		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			for (NSString *JSONKeyPath in JSONKeyPaths) {
				createComponents(JSONDictionary, JSONKeyPath);
				
				[JSONDictionary setValue:value[JSONKeyPath] forKeyPath:JSONKeyPath];
			}
		}
	}];
	
	if (success) {
		return JSONDictionary;
	} else {
		if (error != NULL) *error = tmpError;
		
		return nil;
	}
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	if ([self.modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
		Class class = [self.modelClass classForParsingJSONDictionary:JSONDictionary];
		if (class == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
										   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorNoClassFound userInfo:userInfo];
			}
			
			return nil;
		}
		
		if (class != self.modelClass) {
			NSAssert([class conformsToProtocol:@protocol(MTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MTLJSONSerializing>", class);
			
			MTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:class error:error];
			
			return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
		}
	}
	
	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
	
	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
		
		if (JSONKeyPaths == nil) continue;
		
		id value;
		
		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
			
			for (NSString *keyPath in JSONKeyPaths) {
				BOOL success;
				id value = [JSONDictionary mtl_valueForJSONKeyPath:keyPath success:&success error:error];
				
				if (!success) return nil;
				
				if (value != nil) dictionary[keyPath] = value;
			}
			
			value = dictionary;
		} else {
			BOOL success;
			value = [JSONDictionary mtl_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];
			
			if (!success) return nil;
		}
		
		if (value == nil) continue;
		
		@try {
			NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				
				if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
					id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
					
					BOOL success = YES;
					value = [errorHandlingTransformer transformedValue:value success:&success error:error];
					
					if (!success) return nil;
				} else {
					value = [transformer transformedValue:value];
				}
				
				if (value == nil) value = NSNull.null;
			}
			
			dictionaryValue[propertyKey] = value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);
			
			// Fail fast in Debug builds.
#if DEBUG
			@throw ex;
#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: ex.description,
										   NSLocalizedFailureReasonErrorKey: ex.reason,
										   MTLJSONAdapterThrownExceptionErrorKey: ex
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
			}
			
			return nil;
#endif
		}
	}
	
	id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
	
	return [model validate:error] ? model : nil;
}

- (BOOL)updateModel:(id<MTLJSONSerializing>)model fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	if ([model.class respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
		Class class = [model.class classForParsingJSONDictionary:JSONDictionary];
		if(class!=model.class){
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
										   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Model class be found to parse the JSON dictionary but isn't possible replace class on update.", @"")
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorClassFoundOnUpdate userInfo:userInfo];
			}
			
			return NO;
		}
	}
	
	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
	
	for (NSString *propertyKey in [model.class propertyKeys]) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
		
		if (JSONKeyPaths == nil) continue;
		
		id value;
		
		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
			
			for (NSString *keyPath in JSONKeyPaths) {
				BOOL success;
				id value = [JSONDictionary mtl_valueForJSONKeyPath:keyPath success:&success error:error];
				
				if (!success) return NO;
				
				if (value != nil) dictionary[keyPath] = value;
			}
			
			value = dictionary;
		} else {
			BOOL success;
			value = [JSONDictionary mtl_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];
			
			if (!success) return NO;
		}
		
		if (value == nil) continue;
		
		@try {
			NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				
				if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
					id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
					
					BOOL success = YES;
					value = [errorHandlingTransformer transformedValue:value success:&success error:error];
					
					if (!success) return NO;
				} else {
					value = [transformer transformedValue:value];
				}
				
				if (value == nil) value = NSNull.null;
			}
			
			dictionaryValue[propertyKey] = value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);
			
			// Fail fast in Debug builds.
#if DEBUG
			@throw ex;
#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: ex.description,
										   NSLocalizedFailureReasonErrorKey: ex.reason,
										   MTLJSONAdapterThrownExceptionErrorKey: ex
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
			}
			
			return NO;
#endif
		}
	}
	
	BOOL update = [model updateWithDictionary:dictionaryValue error:error];
	
	return update && [model validate:error];
}

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	for (NSString *key in [modelClass propertyKeys]) {
		SEL selector = MTLSelectorWithKeyPattern(key, "JSONTransformer");
		if ([modelClass respondsToSelector:selector]) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[modelClass methodSignatureForSelector:selector]];
			invocation.target = modelClass;
			invocation.selector = selector;
			[invocation invoke];
			
			__unsafe_unretained id transformer = nil;
			[invocation getReturnValue:&transformer];
			result[key] = transformer;
			continue;
		}
		
		if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
			result[key] = [modelClass JSONTransformerForKey:key];
			continue;
		}
		
		objc_property_t property = class_getProperty(modelClass, key.UTF8String);
		
		if (property == NULL) continue;
		
		mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};
		
		NSValueTransformer *transformer = nil;
		
		if (*(attributes->type) == *(@encode(id))) {
			Class propertyClass = attributes->objectClass;
			
			if (propertyClass != nil) {
				transformer = [self transformerForModelPropertiesOfClass:propertyClass];
			}
			
			if (transformer == nil) transformer = [NSValueTransformer mtl_validatingTransformerForClass:NSObject.class];
		} else {
			transformer = [self transformerForModelPropertiesOfObjCType:attributes->type] ?: [NSValueTransformer mtl_validatingTransformerForClass:NSValue.class];
		}
		
		if (transformer != nil) result[key] = transformer;
	}
	
	return result;
}

- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	@synchronized(self) {
		MTLJSONAdapter *result = [self.JSONAdaptersByModelClass objectForKey:modelClass];
		
		if (result != nil) return result;
		
		result = [[MTLJSONAdapter alloc] initWithModelClass:modelClass];
		
		if (result != nil) {
			[self.JSONAdaptersByModelClass setObject:result forKey:modelClass];
		}
		
		return result;
	}
}

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MTLJSONSerializing>)model {
	return propertyKeys;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	
	SEL selector = MTLSelectorWithKeyPattern(NSStringFromClass(modelClass), "JSONTransformer");
	if (![self respondsToSelector:selector]) return nil;
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation invoke];
	
	__unsafe_unretained id result = nil;
	[invocation getReturnValue:&result];
	return result;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
	NSParameterAssert(objCType != NULL);
	
	if (strcmp(objCType, @encode(BOOL)) == 0) {
		return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
	}
	
	return nil;
}

@end

@implementation MTLJSONAdapter (ValueTransformers)

+ (NSValueTransformer *)NSURLJSONTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end

@implementation MTLJSONAdapter (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSArray *)JSONArrayFromModels:(NSArray *)models {
	return [self JSONArrayFromModels:models error:NULL];
}

+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model {
	return [self JSONDictionaryFromModel:model error:NULL];
}

#pragma clang diagnostic pop

@end
