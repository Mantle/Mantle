//
//  MTLDictionaryManipulationSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(MTLDictionaryManipulationAdditions)

describe(@"-mtl_dictionaryByAddingEntriesFromDictionary:", ^{
	NSDictionary *dict = @{ @"foo": @"bar", @(5): NSNull.null };

	it(@"should return the same dictionary when adding from an empty dictionary", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{}];
		expect(combined).to.equal(dict);
	});

	it(@"should return the same dictionary when adding from nil", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:nil];
		expect(combined).to.equal(dict);
	});

	it(@"should add any new keys", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @"buzz": @(10), @"baz": NSNull.null }];
		NSDictionary *expected = @{ @"foo": @"bar", @(5): NSNull.null, @"buzz": @(10), @"baz": NSNull.null };
		expect(combined).to.equal(expected);
	});

	it(@"should replace any existing keys", ^{
		NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @(5): @(10), @"buzz": @"baz" }];
		NSDictionary *expected = @{ @"foo": @"bar", @(5): @(10), @"buzz": @"baz" };
		expect(combined).to.equal(expected);
	});
});

SpecEnd
