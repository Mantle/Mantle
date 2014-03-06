//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTLTransformerErrorHandling.h"

// The name for a value transformer that converts strings into URLs and back.
extern NSString * const MTLURLValueTransformerName;

// Ensure an NSNumber is backed by __NSCFBoolean/CFBooleanRef
//
// NSJSONSerialization, and likely other serialization libraries, ordinarily
// serialize NSNumbers as numbers, and thus booleans would be serialized as
// 0/1. The exception is when the NSNumber is backed by __NSCFBoolean, which,
// though very much an implementation detail, is detected and serialized as a
// proper boolean.
extern NSString * const MTLBooleanValueTransformerName;

@interface NSValueTransformer (MTLPredefinedTransformerAdditions)

// A reversible value transformer to transform between the keys and objects of a
// dictionary.
//
// dictionary - The dictionary whose keys and values we should transform between.
//
// Can for example be used for transforming between enum values and their string
// representation.
//
//   NSValueTransformer *valueTransformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
//     @"foo": @(EnumDataTypeFoo),
//     @"bar": @(EnumDataTypeBar),
//   }];
//
// Returns a transformer which will map from keys to objects for forward
// transformations, and from objects to keys for reverse transformations.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary;

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass __attribute__((deprecated("Replaced by +[MTLJSONAdapter dictionaryTransformerWithModelClass:]")));

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass __attribute__((deprecated("Replaced by +[MTLJSONAdapter arrayTransformerWithModelClass:]")));

@end
