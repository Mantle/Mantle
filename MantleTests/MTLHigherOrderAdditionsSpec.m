//
//  MTLHigherOrderAdditionsTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 23.01.12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2012 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

SpecBegin(MTLHigherOrderAdditions)

describe(@"dictionary", ^{
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		@"bar", @"foo",
		@"bar", @"buzz",
		[NSNumber numberWithBool:NO], [NSNumber numberWithInt:20],
		@"buzz", @"baz",
		@"foo", @"bar",
		[NSNull null], @"null",
		nil
	];

	describe(@"successful filtering", ^{
		id filterBlock = ^(id key, id value){
			return [key isEqual:@"foo"] || [value isEqual:@"buzz"];
		};

		NSDictionary *filteredDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			@"bar", @"foo",
			@"buzz", @"baz",
			nil
		];

		it(@"should filter", ^{
			expect([dictionary mtl_filterEntriesUsingBlock:filterBlock]).to.equal(filteredDictionary);
		});

		it(@"should filter concurrently", ^{
			expect([dictionary mtl_filterEntriesWithOptions:NSEnumerationConcurrent usingBlock:filterBlock]).to.equal(filteredDictionary);
		});

		it(@"should filter in reverse", ^{
			expect([dictionary mtl_filterEntriesWithOptions:NSEnumerationReverse usingBlock:filterBlock]).to.equal(filteredDictionary);
		});

		it(@"should filter to empty dictionary", ^{
			expect([[NSDictionary dictionary] mtl_filterEntriesUsingBlock:filterBlock]).to.equal([NSDictionary dictionary]);
		});

		NSDictionary *failedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			@"bar", @"buzz",
			[NSNumber numberWithBool:NO], [NSNumber numberWithInt:20],
			@"foo", @"bar",
			[NSNull null], @"null",
			nil
		];

		it(@"should partition", ^{
			__block id failedObjects = nil;
			expect([dictionary mtl_filterEntriesWithFailedEntries:&failedObjects usingBlock:filterBlock]).to.equal(filteredDictionary);
			expect(failedObjects).to.equal(failedDictionary);
		});

		it(@"should partition concurrently", ^{
			__block id failedObjects = nil;
			expect([dictionary mtl_filterEntriesWithOptions:NSEnumerationConcurrent failedEntries:&failedObjects usingBlock:filterBlock]).to.equal(filteredDictionary);
			expect(failedObjects).to.equal(failedDictionary);
		});

		it(@"should partition in reverse", ^{
			__block id failedObjects = nil;
			expect([dictionary mtl_filterEntriesWithOptions:NSEnumerationReverse failedEntries:&failedObjects usingBlock:filterBlock]).to.equal(filteredDictionary);
			expect(failedObjects).to.equal(failedDictionary);
		});

		it(@"should partition even without failed entries", ^{
			expect([dictionary mtl_filterEntriesWithFailedEntries:NULL usingBlock:filterBlock]).to.equal(filteredDictionary);
		});

		it(@"should partition to empty dictionary", ^{
			__block id failedObjects;
			expect([[NSDictionary dictionary] mtl_filterEntriesWithFailedEntries:&failedObjects usingBlock:filterBlock]).to.equal([NSDictionary dictionary]);
			expect(failedObjects).to.equal([NSDictionary dictionary]);
		});
	});

	id unsuccessfulFilterBlock = ^(id key, id value){
		return NO;
	};

	it(@"should filter to empty dictionary when not successful", ^{
		expect([dictionary mtl_filterEntriesUsingBlock:unsuccessfulFilterBlock]).to.equal([NSDictionary dictionary]);
	});

	it(@"should partition to empty dictionary when not successful", ^{
		__block id failedObjects = nil;
		expect([dictionary mtl_filterEntriesWithFailedEntries:&failedObjects usingBlock:unsuccessfulFilterBlock]).to.equal([NSDictionary dictionary]);
		expect(failedObjects).to.equal(dictionary);
	});

	it(@"should return empty failed dictionary from partition when completely successful", ^{
		id successfulFilterBlock = ^(id key, id value){
			return YES;
		};

		__block id failedObjects = nil;
		expect([dictionary mtl_filterEntriesWithFailedEntries:&failedObjects usingBlock:successfulFilterBlock]).to.equal(dictionary);
		expect(failedObjects).to.equal([NSDictionary dictionary]);
	});

	describe(@"successful mapping", ^{
		id mapBlock = ^ id (id key, id value){
			if ([key isKindOfClass:[NSString class]] && [key hasPrefix:@"ba"]) {
				return [value stringByAppendingString:@"buzz"];
			} else {
				return [NSNull null];
			}
		};

		NSDictionary *mappedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNull null], @"foo",
			[NSNull null], @"buzz",
			[NSNull null], [NSNumber numberWithInt:20],
			@"buzzbuzz", @"baz",
			@"foobuzz", @"bar",
			[NSNull null], @"null",
			nil
		];

		it(@"should map", ^{
			expect([dictionary mtl_mapValuesUsingBlock:mapBlock]).to.equal(mappedDictionary);
		});

		it(@"should map concurrently", ^{
			expect([dictionary mtl_mapValuesWithOptions:NSEnumerationConcurrent usingBlock:mapBlock]).to.equal(mappedDictionary);
		});

		it(@"should map in reverse", ^{
			expect([dictionary mtl_mapValuesWithOptions:NSEnumerationReverse usingBlock:mapBlock]).to.equal(mappedDictionary);
		});

		it(@"should map to empty dictionary", ^{
			expect([[NSDictionary dictionary] mtl_mapValuesUsingBlock:mapBlock]).to.equal([NSDictionary dictionary]);
		});
	});

	it(@"should remove elements when mapping block returns nil", ^{
		id removingMapBlock = ^ id (id key, id value){
			if ([key isKindOfClass:[NSString class]] && [key hasPrefix:@"b"]) {
				return [@"buzz" stringByAppendingString:value];
			} else {
				return nil;
			}
		};

		NSDictionary *mappedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			@"buzzbar", @"buzz",
			@"buzzbuzz", @"baz",
			@"buzzfoo", @"bar",
			nil
		];

		expect([dictionary mtl_mapValuesUsingBlock:removingMapBlock]).to.equal(mappedDictionary);
	});

	describe(@"folding", ^{
		id foldBlock = ^(NSString *soFar, id nextKey, NSString *nextValue){
			if (![nextKey isKindOfClass:[NSString class]]) return soFar;
			if (![nextValue isKindOfClass:[NSString class]]) nextValue = @"null";

			if ([nextValue compare:soFar options:0 range:NSMakeRange(1, nextValue.length - 1)] == NSOrderedDescending) {
				return [nextValue substringFromIndex:1];
			} else {
				return soFar;
			}
		};

		NSString *startingValue = @"aaaa";
		NSString *result = @"uzz";

		it(@"should fold", ^{
			expect([dictionary mtl_foldEntriesWithValue:startingValue usingBlock:foldBlock]).to.equal(result);
		});

		it(@"should with nil", ^{
			expect([dictionary mtl_foldEntriesWithValue:nil usingBlock:foldBlock]).to.equal(result);
		});

		it(@"should fold to starting value", ^{
			expect([[NSDictionary dictionary] mtl_foldEntriesWithValue:startingValue usingBlock:foldBlock]).to.equal(startingValue);
		});
	});

	describe(@"successful key of entry passing test", ^{
		id testBlock = ^(id key, id value, BOOL *stop){
			return [value isKindOfClass:[NSNumber class]];
		};

		id key = [NSNumber numberWithInt:20];

		it(@"should return key passing test", ^{
			expect([dictionary mtl_keyOfEntryPassingTest:testBlock]).to.equal(key);
		});

		it(@"should return key passing test concurrently", ^{
			expect([dictionary mtl_keyOfEntryWithOptions:NSEnumerationConcurrent passingTest:testBlock]).to.equal(key);
		});

		it(@"should return key passing test in reverse", ^{
			expect([dictionary mtl_keyOfEntryWithOptions:NSEnumerationReverse passingTest:testBlock]).to.equal(key);
		});
	});
	
	it(@"should not return a key when testing empty dictionary", ^{
		id testBlock = ^(id key, id value, BOOL *stop){
			return YES;
		};

		expect([[NSDictionary dictionary] mtl_keyOfEntryPassingTest:testBlock]).to.beNil();
	});

	it(@"should not return a key when entry test fails", ^{
		id testBlock = ^(id key, id value, BOOL *stop){
			return [key isEqual:@"quux"];
		};

		expect([dictionary mtl_keyOfEntryPassingTest:testBlock]).to.beNil();
	});

	it(@"should not return a key when stopping test", ^{
		__block BOOL firstRun = YES;

		id testBlock = ^(id key, id value, BOOL *stop){
			expect(firstRun).to.beTruthy();

			firstRun = NO;

			*stop = YES;
			return NO;
		};

		expect([dictionary mtl_keyOfEntryPassingTest:testBlock]).to.beNil();
	});
});

id filterBlock = ^(NSString *str){
	return [str isEqualToString:@"bar"] || [str hasSuffix:@"zz"];
};

id mapBlock = ^(NSString *str){
	return [str stringByAppendingString:@"buzz"];
};

id orderedTestBlock = ^(NSString *str, NSUInteger index, BOOL *stop){
	return [str hasPrefix:@"ba"];
};

id unorderedTestBlock = ^(NSString *str, BOOL *stop){
	return [str isEqualToString:@"foo"];
};

id leftFoldBlock = ^(NSString *soFar, NSString *next){
	if ([next compare:soFar options:0 range:NSMakeRange(1, next.length - 1)] == NSOrderedDescending)
		return [next substringFromIndex:1];
	else
		return soFar;
};

id rightFoldBlock = ^(NSString *next, NSString *soFar){
	return [soFar stringByAppendingString:[next substringWithRange:NSMakeRange(1, 1)]];
};

describe(@"non-empty collection", ^{
	NSArray *array = [NSArray arrayWithObjects:@"foo", @"bar", @"baz", @"buzz", nil];
	NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithObjects:@"foo", @"bar", @"baz", @"bizz", nil];
	NSSet *set = [NSSet setWithObjects:@"foo", @"bar", @"baz", @"bozz", nil];

	describe(@"successful filtering", ^{
		NSArray *filteredArray = [NSArray arrayWithObjects:@"bar", @"buzz", nil];
		NSArray *failedArray = [NSArray arrayWithObjects:@"foo", @"baz", nil];

		NSOrderedSet *filteredOrderedSet = [NSOrderedSet orderedSetWithObjects:@"bar", @"bizz", nil];
		NSOrderedSet *failedOrderedSet = [NSOrderedSet orderedSetWithObjects:@"foo", @"baz", nil];

		NSSet *filteredSet = [NSSet setWithObjects:@"bar", @"bozz", nil];
		NSSet *failedSet = [NSSet setWithObjects:@"foo", @"baz", nil];

		it(@"should filter", ^{
			expect([array mtl_filterUsingBlock:filterBlock]).to.equal(filteredArray);
			expect([orderedSet mtl_filterUsingBlock:filterBlock]).to.equal(filteredOrderedSet);
			expect([set mtl_filterUsingBlock:filterBlock]).to.equal(filteredSet);
		});

		it(@"should filter concurrently", ^{
			expect([array mtl_filterWithOptions:NSEnumerationConcurrent usingBlock:filterBlock]).to.equal(filteredArray);
			expect([orderedSet mtl_filterWithOptions:NSEnumerationConcurrent usingBlock:filterBlock]).to.equal(filteredOrderedSet);
			expect([set mtl_filterWithOptions:NSEnumerationConcurrent usingBlock:filterBlock]).to.equal(filteredSet);
		});

		it(@"should filter in reverse", ^{
			expect([array mtl_filterWithOptions:NSEnumerationReverse usingBlock:filterBlock]).to.equal([[filteredArray reverseObjectEnumerator] allObjects]);
			expect([[orderedSet mtl_filterWithOptions:NSEnumerationReverse usingBlock:filterBlock] array]).to.equal([[filteredOrderedSet reverseObjectEnumerator] allObjects]);
			expect([set mtl_filterWithOptions:NSEnumerationReverse usingBlock:filterBlock]).to.equal(filteredSet);
		});

		it(@"should partition even without failed objects", ^{
			expect([array mtl_filterWithFailedObjects:NULL usingBlock:filterBlock]).to.equal(filteredArray);
			expect([orderedSet mtl_filterWithFailedObjects:NULL usingBlock:filterBlock]).to.equal(filteredOrderedSet);
			expect([set mtl_filterWithFailedObjects:NULL usingBlock:filterBlock]).to.equal(filteredSet);
		});

		it(@"should partition", ^{
			__block id failedObjects = nil;

			expect([array mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredArray);
			expect(failedObjects).to.equal(failedArray);

			expect([orderedSet mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredOrderedSet);
			expect(failedObjects).to.equal(failedOrderedSet);

			expect([set mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredSet);
			expect(failedObjects).to.equal(failedSet);
		});

		it(@"should partition concurrently", ^{
			__block id failedObjects = nil;

			expect([array mtl_filterWithOptions:NSEnumerationConcurrent failedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredArray);
			expect(failedObjects).to.equal(failedArray);

			expect([orderedSet mtl_filterWithOptions:NSEnumerationConcurrent failedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredOrderedSet);
			expect(failedObjects).to.equal(failedOrderedSet);

			expect([set mtl_filterWithOptions:NSEnumerationConcurrent failedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredSet);
			expect(failedObjects).to.equal(failedSet);
		});

		it(@"should partition in reverse", ^{
			__block id failedObjects = nil;

			expect([array mtl_filterWithOptions:NSEnumerationReverse failedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredArray.reverseObjectEnumerator.allObjects);
			expect(failedObjects).to.equal(failedArray.reverseObjectEnumerator.allObjects);

			expect([orderedSet mtl_filterWithOptions:NSEnumerationReverse failedObjects:&failedObjects usingBlock:filterBlock].array).to.equal(filteredOrderedSet.reverseObjectEnumerator.allObjects);
			expect([failedObjects allObjects]).to.equal(failedOrderedSet.reverseObjectEnumerator.allObjects);

			expect([set mtl_filterWithOptions:NSEnumerationReverse failedObjects:&failedObjects usingBlock:filterBlock]).to.equal(filteredSet);
			expect(failedObjects).to.equal(failedSet);
		});
	});

	id unsuccessfulFilterBlock = ^(id obj){
		return NO;
	};

	it(@"should filter to empty collection when not successful", ^{
		expect([array mtl_filterUsingBlock:unsuccessfulFilterBlock]).to.equal([NSArray array]);
		expect([orderedSet mtl_filterUsingBlock:unsuccessfulFilterBlock]).to.equal([NSOrderedSet orderedSet]);
		expect([set mtl_filterUsingBlock:unsuccessfulFilterBlock]).to.equal([NSSet set]);
	});

	it(@"should partition to empty collection when not successful", ^{
		__block id failedObjects = nil;

		expect([array mtl_filterWithFailedObjects:&failedObjects usingBlock:unsuccessfulFilterBlock]).to.equal([NSArray array]);
		expect(failedObjects).to.equal(array);

		expect([orderedSet mtl_filterWithFailedObjects:&failedObjects usingBlock:unsuccessfulFilterBlock]).to.equal([NSOrderedSet orderedSet]);
		expect(failedObjects).to.equal(orderedSet);

		expect([set mtl_filterWithFailedObjects:&failedObjects usingBlock:unsuccessfulFilterBlock]).to.equal([NSSet set]);
		expect(failedObjects).to.equal(set);
	});

	it(@"should return empty failed objects from partition when completely successful", ^{
		id successfulFilterBlock = ^(id obj){
			return YES;
		};

		__block id failedObjects = nil;

		expect([array mtl_filterWithFailedObjects:&failedObjects usingBlock:successfulFilterBlock]).to.equal(array);
		expect(failedObjects).to.equal([NSArray array]);

		expect([orderedSet mtl_filterWithFailedObjects:&failedObjects usingBlock:successfulFilterBlock]).to.equal(orderedSet);
		expect(failedObjects).to.equal([NSOrderedSet orderedSet]);

		expect([set mtl_filterWithFailedObjects:&failedObjects usingBlock:successfulFilterBlock]).to.equal(set);
		expect(failedObjects).to.equal([NSSet set]);
	});

	describe(@"successful mapping", ^{
		NSArray *mappedArray = [NSArray arrayWithObjects:@"foobuzz", @"barbuzz", @"bazbuzz", @"buzzbuzz", nil];
		NSOrderedSet *mappedOrderedSet = [NSOrderedSet orderedSetWithObjects:@"foobuzz", @"barbuzz", @"bazbuzz", @"bizzbuzz", nil];
		NSSet *mappedSet = [NSSet setWithObjects:@"foobuzz", @"barbuzz", @"bazbuzz", @"bozzbuzz", nil];

		it(@"should map", ^{
			expect([array mtl_mapUsingBlock:mapBlock]).to.equal(mappedArray);
			expect([orderedSet mtl_mapUsingBlock:mapBlock]).to.equal(mappedOrderedSet);
			expect([set mtl_mapUsingBlock:mapBlock]).to.equal(mappedSet);
		});

		it(@"should map concurrently", ^{
			expect([array mtl_mapWithOptions:NSEnumerationConcurrent usingBlock:mapBlock]).to.equal(mappedArray);
			expect([orderedSet mtl_mapWithOptions:NSEnumerationConcurrent usingBlock:mapBlock]).to.equal(mappedOrderedSet);
			expect([set mtl_mapWithOptions:NSEnumerationConcurrent usingBlock:mapBlock]).to.equal(mappedSet);
		});

		it(@"should map in reverse", ^{
			expect([array mtl_mapWithOptions:NSEnumerationReverse usingBlock:mapBlock]).to.equal(mappedArray.reverseObjectEnumerator.allObjects);
			expect([orderedSet mtl_mapWithOptions:NSEnumerationReverse usingBlock:mapBlock].array).to.equal(mappedOrderedSet.reverseObjectEnumerator.allObjects);
			expect([set mtl_mapWithOptions:NSEnumerationReverse usingBlock:mapBlock]).to.equal(mappedSet);
		});

		it(@"should remove elements when mapping block returns nil", ^{
			id removingMapBlock = ^ id (NSString *str){
				if ([str hasPrefix:@"ba"]) {
					return [str stringByAppendingString:@"buzz"];
				} else {
					return nil;
				}
			};

			id correspondingFilterBlock = ^(NSString *str){
				return [str hasPrefix:@"ba"];
			};

			expect([array mtl_mapUsingBlock:removingMapBlock]).to.equal([mappedArray mtl_filterUsingBlock:correspondingFilterBlock]);
			expect([orderedSet mtl_mapUsingBlock:removingMapBlock]).to.equal([mappedOrderedSet mtl_filterUsingBlock:correspondingFilterBlock]);
			expect([set mtl_mapUsingBlock:removingMapBlock]).to.equal([mappedSet mtl_filterUsingBlock:correspondingFilterBlock]);
		});
	});

	it(@"should remove all elements when mapping block always returns nil", ^{
		id removingMapBlock = ^(NSString *str){
			return nil;
		};

		expect([array mtl_mapUsingBlock:removingMapBlock]).to.equal([NSArray array]);
		expect([orderedSet mtl_mapUsingBlock:removingMapBlock]).to.equal([NSOrderedSet orderedSet]);
		expect([set mtl_mapUsingBlock:removingMapBlock]).to.equal([NSSet set]);
	});

	describe(@"successful object passing test", ^{
		NSUInteger arrayIndex = [array indexOfObject:@"bar"];
		NSUInteger orderedSetIndex = [orderedSet indexOfObject:@"bar"];
		NSString *unorderedObject = @"foo";

		it(@"should return object passing test", ^{
			expect([array mtl_objectPassingTest:orderedTestBlock]).to.equal([array objectAtIndex:arrayIndex]);
			expect([orderedSet mtl_objectPassingTest:orderedTestBlock]).to.equal([orderedSet objectAtIndex:orderedSetIndex]);
			expect([set mtl_objectPassingTest:unorderedTestBlock]).to.equal(unorderedObject);
		});

		it(@"should return object passing test concurrently", ^{
			expect([array mtl_objectWithOptions:NSEnumerationConcurrent passingTest:orderedTestBlock]).to.equal([array objectAtIndex:arrayIndex]);
			expect([orderedSet mtl_objectWithOptions:NSEnumerationConcurrent passingTest:orderedTestBlock]).to.equal([orderedSet objectAtIndex:orderedSetIndex]);
			expect([set mtl_objectWithOptions:NSEnumerationConcurrent passingTest:unorderedTestBlock]).to.equal(unorderedObject);
		});

		it(@"should return object passing test in reverse", ^{
			expect([array mtl_objectWithOptions:NSEnumerationReverse passingTest:orderedTestBlock]).to.equal([array objectAtIndex:array.count - arrayIndex - 1]);
			expect([orderedSet mtl_objectWithOptions:NSEnumerationReverse passingTest:orderedTestBlock]).to.equal([orderedSet objectAtIndex:orderedSet.count - orderedSetIndex - 1]);
			expect([set mtl_objectWithOptions:NSEnumerationReverse passingTest:unorderedTestBlock]).to.equal(unorderedObject);
		});
	});

	it(@"should not return object passing test when test fails", ^{
		id orderedTestBlock = ^(NSString *str, NSUInteger index, BOOL *stop){
			return [str hasPrefix:@"quu"];
		};

		id unorderedTestBlock = ^(NSString *str, BOOL *stop){
			return [str hasPrefix:@"quu"];
		};

		expect([array mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([orderedSet mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([set mtl_objectPassingTest:unorderedTestBlock]).to.beNil();
	});

	it(@"should not return object passing test when stopping test", ^{
		id orderedTestBlock = ^(NSString *str, NSUInteger index, BOOL *stop){
			*stop = YES;
			return [str hasPrefix:@"ba"];
		};

		id unorderedTestBlock = ^(NSString *str, BOOL *stop){
			*stop = YES;

			// assume that -anyObject will return the "first" object that we
			// would be testing, and thus we should only match every other
			// object in the set
			return ![str isEqualToString:[set anyObject]];
		};
		
		expect([array mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([orderedSet mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([set mtl_objectPassingTest:unorderedTestBlock]).to.beNil();
	});

	describe(@"successful left folding", ^{
		NSString *startingValue = @"aaaa";

		NSString *arrayResult = @"uzz";
		NSString *orderedSetResult = @"oo";
		NSString *setResult = @"ozz";

		it(@"should fold", ^{
			expect([array mtl_foldLeftWithValue:startingValue usingBlock:leftFoldBlock]).to.equal(arrayResult);
			expect([orderedSet mtl_foldLeftWithValue:startingValue usingBlock:leftFoldBlock]).to.equal(orderedSetResult);
			expect([set mtl_foldWithValue:startingValue usingBlock:leftFoldBlock]).to.equal(setResult);
		});

		it(@"should fold with nil", ^{
			expect([array mtl_foldLeftWithValue:nil usingBlock:leftFoldBlock]).to.equal(arrayResult);
			expect([orderedSet mtl_foldLeftWithValue:nil usingBlock:leftFoldBlock]).to.equal(orderedSetResult);
			expect([set mtl_foldWithValue:nil usingBlock:leftFoldBlock]).to.equal(setResult);
		});
	});

	it(@"should right fold", ^{
		NSString *startingValue = @"A";

		NSString *arrayResult = @"Auaao";
		NSString *orderedSetResult = @"Aiaao";

		expect([array mtl_foldRightWithValue:startingValue usingBlock:rightFoldBlock]).to.equal(arrayResult);
		expect([orderedSet mtl_foldRightWithValue:startingValue usingBlock:rightFoldBlock]).to.equal(orderedSetResult);
	});

	it(@"should right fold with nil", ^{
		expect([array mtl_foldRightWithValue:nil usingBlock:rightFoldBlock]).to.beNil();
		expect([orderedSet mtl_foldRightWithValue:nil usingBlock:rightFoldBlock]).to.beNil();
	});
});

describe(@"empty collection", ^{
	it(@"should filter to empty collection", ^{
		expect([[NSArray array] mtl_filterUsingBlock:filterBlock]).to.equal([NSArray array]);
		expect([[NSOrderedSet orderedSet] mtl_filterUsingBlock:filterBlock]).to.equal([NSOrderedSet orderedSet]);
		expect([[NSSet set] mtl_filterUsingBlock:filterBlock]).to.equal([NSSet set]);
	});

	it(@"should partition to empty collection", ^{
		__block id failedObjects = nil;
		expect([[NSArray array] mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal([NSArray array]);
		expect(failedObjects).to.equal([NSArray array]);

		expect([[NSOrderedSet orderedSet] mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal([NSOrderedSet orderedSet]);
		expect(failedObjects).to.equal([NSOrderedSet orderedSet]);

		expect([[NSSet set] mtl_filterWithFailedObjects:&failedObjects usingBlock:filterBlock]).to.equal([NSSet set]);
		expect(failedObjects).to.equal([NSSet set]);
	});

	it(@"should map to empty collection", ^{
		expect([[NSArray array] mtl_mapUsingBlock:mapBlock]).to.equal([NSArray array]);
		expect([[NSOrderedSet orderedSet] mtl_mapUsingBlock:mapBlock]).to.equal([NSOrderedSet orderedSet]);
		expect([[NSSet set] mtl_mapUsingBlock:mapBlock]).to.equal([NSSet set]);
	});

	it(@"should not return object passing test", ^{
		expect([[NSArray array] mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([[NSOrderedSet orderedSet] mtl_objectPassingTest:orderedTestBlock]).to.beNil();
		expect([[NSSet set] mtl_objectPassingTest:unorderedTestBlock]).to.beNil();
	});

	it(@"should fold left to starting value", ^{
		id value = @"foobar";

		expect([[NSArray array] mtl_foldLeftWithValue:value usingBlock:leftFoldBlock]).to.equal(value);
		expect([[NSOrderedSet orderedSet] mtl_foldLeftWithValue:value usingBlock:leftFoldBlock]).to.equal(value);
		expect([[NSSet set] mtl_foldWithValue:value usingBlock:leftFoldBlock]).to.equal(value);
	});

	it(@"should fold right to starting value", ^{
		id value = @"foobar";

		expect([[NSArray array] mtl_foldRightWithValue:value usingBlock:rightFoldBlock]).to.equal(value);
		expect([[NSOrderedSet orderedSet] mtl_foldRightWithValue:value usingBlock:rightFoldBlock]).to.equal(value);
	});
});

SpecEnd
