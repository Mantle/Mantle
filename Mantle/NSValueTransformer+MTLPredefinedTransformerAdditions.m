//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLValueTransformer.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";
NSString * const MTLBooleanValueTransformerName = @"MTLBooleanValueTransformerName";

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Category Loading

+ (void)load {
	@autoreleasepool {
		MTLValueTransformer *URLValueTransformer = [MTLValueTransformer
			transformerUsingForwardBlock:^ id (NSString *str, BOOL *success, NSError **error) {
				if (str == nil) return nil;

				if (![str isKindOfClass:NSString.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string to URL", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSString, got: %@.", @""), str],
							MTLTransformerErrorHandlingInputValueErrorKey : str
						};

						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				NSURL *result = [NSURL URLWithString:str];

				if (result == nil) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string to URL", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Input URL string %@ was malformed", @""), str],
							MTLTransformerErrorHandlingInputValueErrorKey : str
						};

						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				return result;
			}
			reverseBlock:^ id (NSURL *URL, BOOL *success, NSError **error) {
				if (URL == nil) return nil;

				if (![URL isKindOfClass:NSURL.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert URL to string", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSURL, got: %@.", @""), URL],
							MTLTransformerErrorHandlingInputValueErrorKey : URL
						};

						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				return URL.absoluteString;
			}];

		[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];

		MTLValueTransformer *booleanValueTransformer = [MTLValueTransformer
			transformerUsingReversibleBlock:^ id (NSNumber *boolean, BOOL *success, NSError **error) {
				if (boolean == nil) return nil;

				if (![boolean isKindOfClass:NSNumber.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert number to boolean-backed number or vice-versa", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSNumber, got: %@.", @""), boolean],
							MTLTransformerErrorHandlingInputValueErrorKey : boolean
						};

						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				return (NSNumber *)(boolean.boolValue ? kCFBooleanTrue : kCFBooleanFalse);
			}];

		[NSValueTransformer setValueTransformer:booleanValueTransformer forName:MTLBooleanValueTransformerName];
	}
}

#pragma mark Customizable Transformers

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	return [MTLValueTransformer
		transformerUsingForwardBlock:^ id (id JSONDictionary, BOOL *success, NSError **error) {
			if (JSONDictionary == nil) return nil;

			if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
						MTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
					};

					*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
		}
		reverseBlock:^ id (id model, BOOL *success, NSError **error) {
			if (model == nil) return nil;

			if (![model isKindOfClass:MTLModel.class] || ![model conformsToProtocol:@protocol(MTLJSONSerializing)]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel object conforming to <MTLJSONSerializing>, got: %@.", @""), model],
						MTLTransformerErrorHandlingInputValueErrorKey : model
					};

					*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return [MTLJSONAdapter JSONDictionaryFromModel:model error:error];
		}];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	id<MTLTransformerErrorHandling> dictionaryTransformer = [self mtl_JSONDictionaryTransformerWithModelClass:modelClass];
	
	return [self mtl_arrayMappingTransformerWithTransformer:dictionaryTransformer];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_arrayMappingTransformerWithTransformer:(NSValueTransformer *)transformer {
	NSParameterAssert(transformer != nil);
	
	id (^forwardBlock)(NSArray *values, BOOL *success, NSError **error) = ^ id (NSArray *values, BOOL *success, NSError **error) {
		if (values == nil) return nil;
		
		if (![values isKindOfClass:NSArray.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
					MTLTransformerErrorHandlingInputValueErrorKey: values
				};
				
				*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
			}
			*success = NO;
			return nil;
		}
		
		NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
		NSInteger index = -1;
		for (id value in values) {
			index++;
			if (value == NSNull.null) {
				[transformedValues addObject:NSNull.null];
				continue;
			}
			
			id transformedValue = nil;
			if ([transformer conformsToProtocol:@protocol(MTLTransformerErrorHandling)]) {
				NSError *underlyingError = nil;
				transformedValue = [(id<MTLTransformerErrorHandling>)transformer transformedValue:value success:success error:&underlyingError];
				
				if (*success == NO) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %d", @""), index],
							NSUnderlyingErrorKey: underlyingError,
							MTLTransformerErrorHandlingInputValueErrorKey: values
						};

						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					return nil;
				}
			} else {
				transformedValue = [transformer transformedValue:value];
			}
			
			if (transformedValue == nil) continue;
			
			[transformedValues addObject:transformedValue];
		}
		
		return transformedValues;
	};
	
	id (^reverseBlock)(NSArray *values, BOOL *success, NSError **error) = nil;
	if (transformer.class.allowsReverseTransformation) {
		reverseBlock = ^ id (NSArray *values, BOOL *success, NSError **error) {
			if (values == nil) return nil;
			
			if (![values isKindOfClass:NSArray.class]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
						MTLTransformerErrorHandlingInputValueErrorKey: values
					};

					*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}
			
			NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
			NSInteger index = -1;
			for (id value in values) {
				index++;
				if (value == NSNull.null) {
					[transformedValues addObject:NSNull.null];
					continue;
				}
				
				id transformedValue = nil;
				if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
					NSError *underlyingError = nil;
					transformedValue = [(id<MTLTransformerErrorHandling>)transformer reverseTransformedValue:value success:success error:&underlyingError];
					
					if (*success == NO) {
						if (error != NULL) {
							NSDictionary *userInfo = @{
								NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
								NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %d", @""), index],
								NSUnderlyingErrorKey: underlyingError,
								MTLTransformerErrorHandlingInputValueErrorKey: values
							};
							
							*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
						}
						return nil;
					}
				} else {
					transformedValue = [transformer reverseTransformedValue:value];
				}
				
				if (transformedValue == nil) continue;
				
				[transformedValues addObject:transformedValue];
			}
			
			return transformedValues;
		};
	}
	if (reverseBlock != nil) {
		return [MTLValueTransformer transformerUsingForwardBlock:forwardBlock reverseBlock:reverseBlock];
	} else {
		return [MTLValueTransformer transformerUsingForwardBlock:forwardBlock];
	}
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);

	return [MTLValueTransformer
			transformerUsingForwardBlock:^ id (id <NSCopying> key, BOOL *success, NSError **error) {
				if (key == nil) key = NSNull.null;
				
				id result = dictionary[key];
				
				if (result == nil) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not find associated value", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1$@ to contain a value for %2$@", @""), dictionary, key],
							MTLTransformerErrorHandlingInputValueErrorKey : key
						};
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				
				return result;
			}
			reverseBlock:^ id (id value, BOOL *success, NSError **error) {
				__block id result = nil;
				[dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id anObject, BOOL *stop) {
					if ([value isEqual:anObject]) {
						result = key;
						*stop = YES;
					}
				}];
				
				if (result == nil) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not find associated key", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1$@ to contain a key that maps to %2$@", @""), dictionary, value],
							MTLTransformerErrorHandlingInputValueErrorKey : value
						};
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				
				return result;
			}];
}

@end
