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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass {
	return [MTLJSONAdapter dictionaryTransformerWithModelClass:modelClass];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	return [MTLJSONAdapter arrayTransformerWithModelClass:modelClass];
}

#pragma clang diagnostic pop

@end
