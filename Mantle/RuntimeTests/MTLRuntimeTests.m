//
//  MTLRuntimeTests.m
//  Mantle
//
//  Created by Anton Bukov on 3/11/16.
//  Copyright (c) 2016 ML-Works. All rights reserved.
//

#if __has_include(<Mantle/Mantle.h>)

#import <XCTest/XCTest.h>
#import <Mantle/Mantle.h>
#import "MTLRuntimeRoutines.h"

#pragma mark - Fail example for testJSONKeyPathsByPropertyKey

@interface MTLRuntimeClass_testJSONKeyPathsByPropertyKey : MTLModel <MTLJSONSerializing>
@end
@implementation MTLRuntimeClass_testJSONKeyPathsByPropertyKey
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{ @"a": @"hello" };
}
@end

@interface MTLRuntimeSubclass_testJSONKeyPathsByPropertyKey : MTLRuntimeClass_testJSONKeyPathsByPropertyKey
@end
@implementation MTLRuntimeSubclass_testJSONKeyPathsByPropertyKey
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{ @"b": @"world" };
}
@end

#pragma mark - Fail example for testJSONTransformerForKey

@interface MTLRuntimeClass_testJSONTransformerForKey : MTLModel <MTLJSONSerializing>
@end
@implementation MTLRuntimeClass_testJSONTransformerForKey
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{ @"a": @"hello" };
}
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
	return @{
		@"a": [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName],
	}[key];
}
@end

@interface MTLRuntimeSubclass_testJSONTransformerForKey : MTLRuntimeClass_testJSONTransformerForKey
@end
@implementation MTLRuntimeSubclass_testJSONTransformerForKey
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return [super.JSONKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary:@{ @"b": @"world" }];
}
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
	return @{
		@"b": [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName],
	}[key];
}
@end

#pragma mark - Tests

@interface MTLRuntimeTests : XCTestCase

@end

@implementation MTLRuntimeTests

- (void)testJSONKeyPathsByPropertyKey
{
	__block BOOL foundMTLRuntimeSubclass = NO;
	
	MTLRuntimeEnumerateClasses(^(Class class){
		if ([class respondsToSelector:@selector(JSONKeyPathsByPropertyKey)] &&
			[class.superclass respondsToSelector:@selector(JSONKeyPathsByPropertyKey)]) {
			
			NSSet *keys = [NSSet setWithArray:[class JSONKeyPathsByPropertyKey].allKeys];
			NSSet *superkeys = [NSSet setWithArray:[class.superclass JSONKeyPathsByPropertyKey].allKeys];
			
			if (![superkeys isSubsetOfSet:keys]) {
				if (class == [MTLRuntimeSubclass_testJSONKeyPathsByPropertyKey class]) {
					foundMTLRuntimeSubclass = YES;
				}
				else {
					XCTFail(@"Class %@ should call supers method JSONKeyPathsByPropertyKey like this: [super.JSONKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary:@{...}];", class);
				}
			}
		}
	});
	
	XCTAssertTrue(foundMTLRuntimeSubclass, @"Test is broken!");
}

- (void)testJSONTransformerForKey
{
	__block BOOL foundMTLRuntimeSubclass = NO;
	
	MTLRuntimeEnumerateClasses(^(Class class){
		if ([class respondsToSelector:@selector(JSONTransformerForKey:)] &&
			[class.superclass respondsToSelector:@selector(JSONTransformerForKey:)]) {
			
			NSMutableSet *keys = [NSMutableSet set];
			for (NSString *key in [class JSONKeyPathsByPropertyKey].allKeys) {
				if ([class JSONTransformerForKey:key]) {
					[keys addObject:key];
				}
			}
			
			NSMutableSet *superkeys = [NSMutableSet set];
			for (NSString *key in [class.superclass JSONKeyPathsByPropertyKey].allKeys) {
				if ([class.superclass JSONTransformerForKey:key]) {
					[superkeys addObject:key];
				}
			}
			
			if (![superkeys isSubsetOfSet:keys]) {
				if (class == [MTLRuntimeSubclass_testJSONTransformerForKey class]) {
					foundMTLRuntimeSubclass = YES;
				}
				else {
					XCTFail(@"Class %@ should call supers method JSONTransformerForKey like this: return [super JSONTransformerForKey:key] ?: @{...}[key];", class);
				}
			}
		}
	});
	
	XCTAssertTrue(foundMTLRuntimeSubclass, @"Test is broken!");
}

@end

#endif
