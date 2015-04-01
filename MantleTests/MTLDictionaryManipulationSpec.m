//
//  MTLDictionaryManipulationSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

QuickSpecBegin(MTLDictionaryManipulationAdditions)

describe(@"-mtl_dictionaryByAddingEntriesFromDictionary:", ^{
	NSDictionary *dict = @{ @"foo": @"bar", @(5): NSNull.null };

	it(@"should return the same dictionary when adding from an empty dictionary", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{}];
		expect(combined).to(equal(dict));
	});

	it(@"should return the same dictionary when adding from nil", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:nil];
		expect(combined).to(equal(dict));
	});

	it(@"should add any new keys", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @"buzz": @(10), @"baz": NSNull.null }];
		NSDictionary *expected = @{ @"foo": @"bar", @(5): NSNull.null, @"buzz": @(10), @"baz": NSNull.null };
		expect(combined).to(equal(expected));
	});

	it(@"should replace any existing keys", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @(5): @(10), @"buzz": @"baz" }];
		NSDictionary *expected = @{ @"foo": @"bar", @(5): @(10), @"buzz": @"baz" };
		expect(combined).to(equal(expected));
	});
});

describe(@"-mtl_dictionaryByRemovingValuesForKeys:", ^{
	NSDictionary *dict = @{ @"foo": @"bar", @(5): NSNull.null };

	it(@"should return the same dictionary when removing keys that don't exist in the receiver", ^{
		NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:@[ @"hi"]];
		expect(removed).to(equal(dict));
	});

	it(@"should return the same dictionary when given a nil array of keys", ^{
		NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:nil];
		expect(removed).to(equal(dict));
	});

	it(@"should remove all the entries for the given keys", ^{
		NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:@[ @5 ]];
		NSDictionary *expected = @{ @"foo": @"bar" };
		expect(removed).to(equal(expected));
	});

	it(@"should return an empty dictionary when it removes all its keys", ^{
		NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:dict.allKeys];
		NSDictionary *expected = @{};
		expect(removed).to(equal(expected));
	});
});

QuickSpecEnd
