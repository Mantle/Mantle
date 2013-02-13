//
//  MTLJSONAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLJSONAdapter.h"
#import "MTLModel.h"

@interface MTLJSONAdapter ()

// Looks up the NSValueTransformer that should be used for the given key.
//
// key		  - The property key to transform from or to. This argument must not
//				be nil.
// modelClass - The MTLModel subclass from which to retrieve the transformer.
//				This argument must not be nil.
//
// Returns a transformer to use, or nil to not transform the property.
- (NSValueTransformer *)JSONTransformerForKey:(NSString *)key modelClass:(Class)modelClass;

// Looks up the JSON key path that corresponds to the given key.
//
// key		  - The property key to retrieve the corresponding JSON key path
//				for. This argument must not be nil.
// modelClass - The MTLModel subclass from which to retrieve the key path.
//				This argument must not be nil.
//
// Returns a key path to use, or nil to omit the property from JSON.
- (NSString *)JSONKeyPathForKey:(NSString *)key modelClass:(Class)modelClass;

@end

@implementation MTLJSONAdapter

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary {
	MTLJSONAdapter *adapter = [[self alloc] initWithJSONDictionary:JSONDictionary modelClass:modelClass];
	return adapter.model;
}

+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model {
	MTLJSONAdapter *adapter = [[self alloc] initWithModel:model];
	return adapter.JSONDictionary;
}

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ must be initialized with a JSON dictionary or model object", self.class);
	return nil;
}

- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	if (JSONDictionary == nil) return nil;

	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];

	for (NSString *propertyKey in [modelClass propertyKeys]) {
		NSString *JSONKeyPath = [self JSONKeyPathForKey:propertyKey modelClass:modelClass];
		if (JSONKeyPath == nil) continue;

		id value = [JSONDictionary valueForKeyPath:JSONKeyPath];
		if (value == nil) continue;

		@try {
			NSValueTransformer *transformer = [self JSONTransformerForKey:propertyKey modelClass:modelClass];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				value = [transformer transformedValue:value] ?: NSNull.null;
			}

			dictionaryValue[propertyKey] = value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPath, JSONDictionary);

			// Fail fast in Debug builds.
			#if DEBUG
			@throw ex;
			#endif
		}
	}

	id model = [modelClass modelWithDictionary:dictionaryValue];
	if (model == nil) return nil;

	return [self initWithModel:model];
}

- (id)initWithModel:(MTLModel<MTLJSONSerializing> *)model {
	NSParameterAssert(model != nil);

	self = [super init];
	if (self == nil) return nil;

	_model = model;

	return self;
}

#pragma mark Serialization

- (NSDictionary *)JSONDictionary {
	NSDictionary *dictionaryValue = self.model.dictionaryValue;
	NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];

	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		NSString *JSONKeyPath = [self JSONKeyPathForKey:propertyKey modelClass:self.model.class];
		if (JSONKeyPath == nil) return;

		NSValueTransformer *transformer = [self JSONTransformerForKey:propertyKey modelClass:self.model.class];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionaryValue we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;
			value = [transformer reverseTransformedValue:value] ?: NSNull.null;
		}

		NSArray *keyPathComponents = [JSONKeyPath componentsSeparatedByString:@"."];

		// Set up dictionaries at each step of the key path.
		id obj = JSONDictionary;
		for (NSString *component in keyPathComponents) {
			if ([obj valueForKey:component] == nil) {
				// Insert an empty mutable dictionary at this spot so that we
				// can set the whole key path afterward.
				[obj setValue:[NSMutableDictionary dictionary] forKey:component];
			}

			obj = [obj valueForKey:component];
		}

		[JSONDictionary setValue:value forKeyPath:JSONKeyPath];
	}];

	return [JSONDictionary copy];
}

- (NSValueTransformer *)JSONTransformerForKey:(NSString *)key modelClass:(Class)modelClass {
	NSParameterAssert(key != nil);
	NSParameterAssert(modelClass != nil);

	SEL selector = NSSelectorFromString([key stringByAppendingString:@"JSONTransformer"]);
	if ([modelClass respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[modelClass methodSignatureForSelector:selector]];
		invocation.target = modelClass;
		invocation.selector = selector;
		[invocation invoke];

		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}

	if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
		return [modelClass JSONTransformerForKey:key];
	}

	return nil;
}

- (NSString *)JSONKeyPathForKey:(NSString *)key modelClass:(Class)modelClass {
	NSParameterAssert(key != nil);
	NSParameterAssert(modelClass != nil);

	NSString *JSONKeyPath = key;
	if ([modelClass respondsToSelector:@selector(JSONKeyPathsByPropertyKey)]) {
		id value = [modelClass JSONKeyPathsByPropertyKey][key];

		if ([value isEqual:NSNull.null]) return nil;
		if (value != nil) JSONKeyPath = value;
	}

	return JSONKeyPath;
}

@end
