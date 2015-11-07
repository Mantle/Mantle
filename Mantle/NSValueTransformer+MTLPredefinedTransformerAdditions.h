//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTLTransformerErrorHandling.h"

/// The name for a value transformer that converts strings into URLs and back.
extern NSString * const MTLURLValueTransformerName;

/// Ensure an NSNumber is backed by __NSCFBoolean/CFBooleanRef
///
/// NSJSONSerialization, and likely other serialization libraries, ordinarily
/// serialize NSNumbers as numbers, and thus booleans would be serialized as
/// 0/1. The exception is when the NSNumber is backed by __NSCFBoolean, which,
/// though very much an implementation detail, is detected and serialized as a
/// proper boolean.
extern NSString * const MTLBooleanValueTransformerName;

@interface NSValueTransformer (MTLPredefinedTransformerAdditions)

/// An optionally reversible transformer which applies the given transformer to
/// each element of an array.
///
/// transformer - The transformer to apply to each element. If the transformer
///               is reversible, the transformer returned by this method will be
///               reversible. This argument must not be nil.
///
/// Returns a transformer which applies a transformation to each element of an
/// array.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_arrayMappingTransformerWithTransformer:(NSValueTransformer *)transformer;

/// A reversible value transformer to transform between the keys and objects of a
/// dictionary.
///
/// dictionary          - The dictionary whose keys and values should be
///                       transformed between. This argument must not be nil.
/// defaultValue        - The result to fall back to, in case no key matching the
///                       input value was found during a forward transformation.
/// reverseDefaultValue - The result to fall back to, in case no value matching
///                       the input value was found during a reverse
///                       transformation.
///
/// Can for example be used for transforming between enum values and their string
/// representation.
///
///   NSValueTransformer *valueTransformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
///     @"foo": @(EnumDataTypeFoo),
///     @"bar": @(EnumDataTypeBar),
///   } defaultValue: @(EnumDataTypeUndefined) reverseDefaultValue: @"undefined"];
///
/// Returns a transformer which will map from keys to objects for forward
/// transformations, and from objects to keys for reverse transformations.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary defaultValue:(id)defaultValue reverseDefaultValue:(id)reverseDefaultValue;

/// Returns a value transformer created by calling
/// `+mtl_valueMappingTransformerWithDictionary:defaultValue:reverseDefaultValue:`
/// with a default value of `nil` and a reverse default value of `nil`.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary;

/// A reversible value transformer to transform between a date and its string
/// representation
///
/// dateFormat - The date format used by the date formatter (http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Field_Symbol_Table)
/// calendar   - The calendar used by the date formatter
/// locale     - The locale used by the date formatter
/// timeZone   - The time zone used by the date formatter
///
/// Returns a transformer which will map from strings to dates for forward
/// transformations, and from dates to strings for reverse transformations.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_dateTransformerWithDateFormat:(NSString *)dateFormat calendar:(NSCalendar *)calendar locale:(NSLocale *)locale timeZone:(NSTimeZone *)timeZone defaultDate:(NSDate *)defaultDate;

/// Returns a value transformer created by calling
/// `+mtl_dateTransformerWithDateFormat:calendar:locale:timeZone:defaultDate:`
/// with a calendar, locale, time zone and default date of `nil`.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_dateTransformerWithDateFormat:(NSString *)dateFormat locale:(NSLocale *)locale;

/// A reversible value transformer to transform between a number and its string
/// representation
///
/// numberStyle - The number style used by the number formatter
///
/// Returns a transformer which will map from strings to numbers for forward
/// transformations, and from numbers to strings for reverse transformations.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_numberTransformerWithNumberStyle:(NSNumberFormatterStyle)numberStyle locale:(NSLocale *)locale;

/// A reversible value transformer to transform between an object and its string
/// representation
///
/// formatter   - The formatter used to perform the transformation
/// objectClass - The class of object that the formatter operates on
///
/// Returns a transformer which will map from strings to objects for forward
/// transformations, and from objects to strings for reverse transformations.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_transformerWithFormatter:(NSFormatter *)formatter forObjectClass:(Class)objectClass;

/// A value transformer that errors if the transformed value are not of the given
/// class.
///
/// class - The expected class. This argument must not be nil.
///
/// Returns a transformer which will return an error if the transformed in value
/// is not a member of class. Otherwise, the value is simply passed through.
+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_validatingTransformerForClass:(Class)modelClass;

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass __attribute__((deprecated("Replaced by +[MTLJSONAdapter dictionaryTransformerWithModelClass:]")));

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass __attribute__((deprecated("Replaced by +[MTLJSONAdapter arrayTransformerWithModelClass:]")));

@end
