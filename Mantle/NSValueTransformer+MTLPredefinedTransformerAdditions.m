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
#import "NSArray+MTLHigherOrderAdditions.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";
NSString * const MTLBooleanValueTransformerName = @"MTLBooleanValueTransformerName";

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Category Loading

+ (void)load {
	@autoreleasepool {
		MTLValueTransformer *URLValueTransformer = [MTLValueTransformer
			reversibleTransformerWithForwardBlock:^ id (NSString *str) {
				if (![str isKindOfClass:NSString.class]) return nil;
				return [NSURL URLWithString:str];
			}
			reverseBlock:^ id (NSURL *URL) {
				if (![URL isKindOfClass:NSURL.class]) return nil;
				return URL.absoluteString;
			}];
		
		[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];

		MTLValueTransformer *booleanValueTransformer = [MTLValueTransformer
			reversibleTransformerWithBlock:^ id (NSNumber *boolean) {
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
		reversibleTransformerWithForwardBlock:^ id (NSDictionary *JSONDictionary) {
			if (JSONDictionary == nil) return nil;

			NSAssert([JSONDictionary isKindOfClass:NSDictionary.class], @"Expected a dictionary, got: %@", JSONDictionary);

			MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:JSONDictionary modelClass:modelClass];
			return adapter.model;
		}
		reverseBlock:^ id (MTLModel<MTLJSONSerializing> *model) {
			if (model == nil) return nil;

			NSAssert([model isKindOfClass:MTLModel.class], @"Expected a MTLModel object, got %@", model);
			NSAssert([model conformsToProtocol:@protocol(MTLJSONSerializing)], @"Expected a model object conforming to <MTLJSONSerializing>, got %@", model);

			MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModel:model];
			return adapter.JSONDictionary;
		}];
}

+ (NSValueTransformer *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer *dictionaryTransformer = [self mtl_JSONDictionaryTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^ id (NSArray *dictionaries) {
			if (dictionaries == nil) return nil;

			NSAssert([dictionaries isKindOfClass:NSArray.class], @"Expected a array of dictionaries, got: %@", dictionaries);

			return [dictionaries mtl_mapUsingBlock:^(NSDictionary *JSONDictionary) {
				return [dictionaryTransformer transformedValue:JSONDictionary];
			}];
		}
		reverseBlock:^ id (NSArray *models) {
			if (models == nil) return nil;

			NSAssert([models isKindOfClass:NSArray.class], @"Expected a array of MTLModels, got: %@", models);

			return [models mtl_mapUsingBlock:^(MTLModel *model) {
				return [dictionaryTransformer reverseTransformedValue:model];
			}];
		}];
}

@end
