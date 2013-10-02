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
			reversibleTransformerWithForwardTransformation:^ id (NSString *str, NSError **error) {
				if (![str isKindOfClass:NSString.class]) return nil;
				return [NSURL URLWithString:str];
			}
			reverseTransformation:^ id (NSURL *URL, NSError **error) {
				if (![URL isKindOfClass:NSURL.class]) return nil;
				return URL.absoluteString;
			}];
		
		[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];

		MTLValueTransformer *booleanValueTransformer = [MTLValueTransformer
			reversibleTransformerWithTransformation:^ id (NSNumber *boolean, NSError **error) {
				if (![boolean isKindOfClass:NSNumber.class]) return nil;
				return (NSNumber *)(boolean.boolValue ? kCFBooleanTrue : kCFBooleanFalse);
			}];

		[NSValueTransformer setValueTransformer:booleanValueTransformer forName:MTLBooleanValueTransformerName];
	}
}

#pragma mark Customizable Transformers

+ (NSValueTransformer *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	return [MTLValueTransformer
		reversibleTransformerWithForwardTransformation:^ id (id JSONDictionary, NSError **error) {
			if (JSONDictionary == nil) return nil;

			NSAssert([JSONDictionary isKindOfClass:NSDictionary.class], @"Expected a dictionary, got: %@", JSONDictionary);

			return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
		}
		reverseTransformation:^ id (id model, NSError **error) {
			if (model == nil) return nil;

			NSAssert([model isKindOfClass:MTLModel.class], @"Expected a MTLModel object, got %@", model);
			NSAssert([model conformsToProtocol:@protocol(MTLJSONSerializing)], @"Expected a model object conforming to <MTLJSONSerializing>, got %@", model);

			return [MTLJSONAdapter JSONDictionaryFromModel:model];
		}];
}

+ (NSValueTransformer *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer *dictionaryTransformer = [self mtl_JSONDictionaryTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		reversibleTransformerWithForwardTransformation:^ id (NSArray *dictionaries, NSError **error) {
			if (dictionaries == nil) return nil;

			NSAssert([dictionaries isKindOfClass:NSArray.class], @"Expected a array of dictionaries, got: %@", dictionaries);

			NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
			for (id JSONDictionary in dictionaries) {
				if (JSONDictionary == NSNull.null) {
					[models addObject:NSNull.null];
					continue;
				}

				NSAssert([JSONDictionary isKindOfClass:NSDictionary.class], @"Expected a dictionary or an NSNull, got: %@", JSONDictionary);

				id model = [dictionaryTransformer transformedValue:JSONDictionary];
				if (model == nil) continue;

				[models addObject:model];
			}

			return models;
		}
		reverseTransformation:^ id (NSArray *models, NSError **error) {
			if (models == nil) return nil;

			NSAssert([models isKindOfClass:NSArray.class], @"Expected a array of MTLModels, got: %@", models);

			NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
			for (id model in models) {
				if (model == NSNull.null) {
					[dictionaries addObject:NSNull.null];
					continue;
				}

				NSAssert([model isKindOfClass:MTLModel.class], @"Expected an MTLModel or an NSNull, got: %@", model);

				NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model];
				if (dict == nil) continue;

				[dictionaries addObject:dict];
			}

			return dictionaries;
		}];
}

+ (NSValueTransformer *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);

	return [MTLValueTransformer reversibleTransformerWithForwardTransformation:^(id<NSCopying> key, NSError **error) {
		return dictionary[key];
	} reverseTransformation:^(id object, NSError **error) {
		__block id result = nil;
		[dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id anObject, BOOL *stop) {
			if ([object isEqual:anObject]) {
				result = key;
				*stop = YES;
			}
		}];
		return result;
	}];
}

@end
