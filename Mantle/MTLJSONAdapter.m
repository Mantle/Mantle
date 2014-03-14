//
//  MTLJSONAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLTransformerErrorHandling.h"
#import "MTLReflection.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

NSString * const MTLJSONAdapterErrorDomain = @"MTLJSONAdapterErrorDomain";
const NSInteger MTLJSONAdapterErrorNoClassFound = 2;
const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary = 3;

// An exception was thrown and caught.
const NSInteger MTLJSONAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MTLJSONAdapterThrownExceptionErrorKey = @"MTLJSONAdapterThrownException";

@interface MTLJSONAdapter ()

// The MTLModel subclass being parsed, or the class of `model` if parsing has
// completed.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +JSONKeyPathsByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;

// A cache of the return value of -valueTransformersForModelClass:
@property (nonatomic, copy, readonly) NSDictionary *valueTransformersByPropertyKey;

// Collect all value transformers needed for a given class.
//
// modelClass - The MTLModel subclass to attempt to parse from the JSON.
//              This class must conform to <MTLJSONSerializing>. This argument
//              must not be nil.
//
// Returns a dictionary with the properties of modelClass that need
// transformation as keys and the value transformers as values.
- (NSDictionary *)valueTransformersForModelClass:(Class)class;

@end

@implementation MTLJSONAdapter

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithJSONDictionary:JSONDictionary modelClass:modelClass error:error];
	return adapter.model;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithModel:model];

	return [adapter serializeToJSONDictionary:error];
}

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ must be initialized with a JSON dictionary or model object", self.class);
	return nil;
}

- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	if (JSONDictionary == nil || ![JSONDictionary isKindOfClass:NSDictionary.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON dictionary", @""),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON dictionary was provided: %@", @""), NSStringFromClass(modelClass), JSONDictionary.class],
			};
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}

	if ([modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
		modelClass = [modelClass classForParsingJSONDictionary:JSONDictionary];
		if (modelClass == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorNoClassFound userInfo:userInfo];
			}

			return nil;
		}

		NSAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MTLJSONSerializing>", modelClass);
	}

	self = [super init];
	if (self == nil) return nil;

	_modelClass = modelClass;
	_JSONKeyPathsByPropertyKey = [[modelClass JSONKeyPathsByPropertyKey] copy];
	_valueTransformersByPropertyKey = [self valueTransformersForModelClass:modelClass];

	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];

	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];

		if (JSONKeyPaths == nil) continue;

		id value;

		@try {
			if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
				value = [JSONDictionary dictionaryWithValuesForKeys:JSONKeyPaths];
			} else {
				value = [JSONDictionary valueForKeyPath:JSONKeyPaths];
			}
		} @catch (NSException *ex) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", nil),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%1$@ could not be parsed because an invalid JSON dictionary was provided for \"%2$@\"", nil), modelClass, JSONKeyPaths],
					MTLJSONAdapterThrownExceptionErrorKey: ex
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
			}

			return nil;
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

	_model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
	if (_model == nil) return nil;

	return self;
}

- (id)initWithModel:(id<MTLJSONSerializing>)model {
	NSParameterAssert(model != nil);

	self = [super init];
	if (self == nil) return nil;

	_model = model;
	_modelClass = model.class;
	_JSONKeyPathsByPropertyKey = [[model.class JSONKeyPathsByPropertyKey] copy];
	_valueTransformersByPropertyKey = [self valueTransformersForModelClass:model.class];

	return self;
}

#pragma mark Serialization

- (NSDictionary *)serializeToJSONDictionary:(NSError **)error {
	NSDictionary *dictionaryValue = self.model.dictionaryValue;
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

		void (^createComponents)(id, NSArray *) = ^(id obj, NSArray *keyPathComponents) {
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
			createComponents(JSONDictionary, [JSONKeyPaths componentsSeparatedByString:@"."]);

			[JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
		}

		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			for (NSString *JSONKeyPath in JSONKeyPaths) {
				createComponents(JSONDictionary, [JSONKeyPath componentsSeparatedByString:@"."]);

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

- (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	for (NSString *key in [modelClass propertyKeys]) {
		SEL selector = MTLSelectorWithKeyPattern(key, "JSONTransformer");
		if ([self.modelClass respondsToSelector:selector]) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.modelClass methodSignatureForSelector:selector]];
			invocation.target = self.modelClass;
			invocation.selector = selector;
			[invocation invoke];

			__unsafe_unretained id transformer = nil;
			[invocation getReturnValue:&transformer];
			result[key] = transformer;
			continue;
		}

		if ([self.modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
			result[key] = [self.modelClass JSONTransformerForKey:key];
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

- (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)class {
	NSParameterAssert(class != nil);

	SEL selector = MTLSelectorWithKeyPattern(NSStringFromClass(class), "JSONTransformer");
	if (![self respondsToSelector:selector]) return nil;

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation invoke];

	__unsafe_unretained id result = nil;
	[invocation getReturnValue:&result];
	return result;
}

- (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
	NSParameterAssert(objCType != NULL);

	if (strcmp(objCType, @encode(BOOL)) == 0) {
		return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
	}

	return nil;
}

@end

@implementation MTLJSONAdapter (ValueTransformers)

- (NSValueTransformer *)NSURLJSONTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end

@implementation MTLJSONAdapter (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model {
	return [self JSONDictionaryFromModel:model error:NULL];
}

- (NSDictionary *)JSONDictionary {
	return [self serializeToJSONDictionary:NULL];
}

#pragma clang diagnostic pop

@end
