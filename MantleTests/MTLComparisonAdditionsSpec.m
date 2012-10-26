//
//  MTLComparisonAdditionsSpec.m
//  Mantle
//
//  Created by Josh Vera on 10/26/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import "NSObject+MTLComparisonAdditions.h"

SpecBegin(MTLComparisonAdditions)

describe(@"MTLEqualObjects", ^{
	id obj1 = @"Test1";
	id obj2 = @"Test2";

	it(@"returns true when given two values of nil", ^{
		expect(MTLEqualObjects(nil, nil)).to.beTruthy();
	});

	it(@"returns true when given two equal objects", ^{
		expect(MTLEqualObjects(obj1, obj1)).to.beTruthy();
	});

	it(@"returns false when given two inequal objects", ^{
		expect(MTLEqualObjects(obj1, obj2)).to.beFalsy();
	});

	it(@"returns false when given an object and nil", ^{
		expect(MTLEqualObjects(obj1, nil)).to.beFalsy();
	});

	it(@"returns the same value when given symmetric arguments", ^{
		expect(MTLEqualObjects(obj2, obj1)).to.equal(MTLEqualObjects(obj1, obj2));
	});
});

SpecEnd
