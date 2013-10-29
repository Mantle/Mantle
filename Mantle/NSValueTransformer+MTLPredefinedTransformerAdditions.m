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

NSString * const MTLPredefinedTransformerErrorDomain = @"MTLPredefinedTransformerErrorDomain";

NSString * const MTLPredefinedTransformerErrorInputValueErrorKey = @"MTLPredefinedTransformerErrorInputValueErrorKey";

const NSInteger MTLInvalidTransformationErrorInvalidInput = 1;

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
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert string to URL", @""),
							NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSString, got: %@.", @""), str],
							MTLPredefinedTransformerErrorInputValueErrorKey : str
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				NSURL *result = [NSURL URLWithString:str];

				if (result == nil) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert string to URL", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Input URL string %@ was malformed", @""), str],
							MTLPredefinedTransformerErrorInputValueErrorKey : str
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
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
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert URL to string", @""),
							NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSURL, got: %@.", @""), URL],
							MTLPredefinedTransformerErrorInputValueErrorKey : URL
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
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
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert number to boolean-backed number or vice-versa", @""),
							NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSNumber, got: %@.", @""), boolean],
							MTLPredefinedTransformerErrorInputValueErrorKey : boolean
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
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
						NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
						NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
						MTLPredefinedTransformerErrorInputValueErrorKey : JSONDictionary
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
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
						NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
						NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel object conforming to <MTLJSONSerializing>, got: %@.", @""), model],
						MTLPredefinedTransformerErrorInputValueErrorKey : model
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return [MTLJSONAdapter JSONDictionaryFromModel:model error:error];
		}];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	id<MTLTransformerErrorHandling> dictionaryTransformer = [self mtl_JSONDictionaryTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		transformerUsingForwardBlock:^ id (NSArray *dictionaries, BOOL *success, NSError **error) {
			if (dictionaries == nil) return nil;

			if (![dictionaries isKindOfClass:NSArray.class]) {
				if (error != NULL) {

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert JSON array to model array", @""),
						NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries],
						MTLPredefinedTransformerErrorInputValueErrorKey : dictionaries
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
			for (id JSONDictionary in dictionaries) {
				if (JSONDictionary == NSNull.null) {
					[models addObject:NSNull.null];
					continue;
				}

				if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert JSON array to model array", @""),
							NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary],
							MTLPredefinedTransformerErrorInputValueErrorKey : JSONDictionary
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				id model = [dictionaryTransformer transformedValue:JSONDictionary success:success error:error];

				if (*success == NO) return nil;

				if (model == nil) continue;

				[models addObject:model];
			}

			return models;
		}
		reverseBlock:^ id (NSArray *models, BOOL *success, NSError **error) {
			if (models == nil) return nil;

			if (![models isKindOfClass:NSArray.class]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert model array to JSON array", @""),
						NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), models],
						MTLPredefinedTransformerErrorInputValueErrorKey : models
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
			for (id model in models) {
				if (model == NSNull.null) {
					[dictionaries addObject:NSNull.null];
					continue;
				}

				if (![model isKindOfClass:MTLModel.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert JSON array to model array", @""),
							NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel or an NSNull, got: %@.", @""), model],
							MTLPredefinedTransformerErrorInputValueErrorKey : model
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput	userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model success:success error:error];

				if (*success == NO) return nil;

				if (dict == nil) continue;

				[dictionaries addObject:dict];
			}

			return dictionaries;
		}];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);

	return [MTLValueTransformer
		transformerUsingForwardBlock:^ id (id <NSCopying> key, BOOL *success, NSError **error) {
			id result = dictionary[key];

			if (result == nil) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not find associated value", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1@ to contain a value for %2@", @""), dictionary, key],
						MTLPredefinedTransformerErrorInputValueErrorKey: key
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
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
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1@ to contain a key that maps to %2@", @""), dictionary, value],
						MTLPredefinedTransformerErrorInputValueErrorKey: value
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLInvalidTransformationErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return result;
		}];
}

@end
