//
//  MAVArrayManipulationSpec.m
//  Maverick
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+MAVManipulationAdditions.h"

SpecBegin(MAVArrayManipulationAdditions)

describe(@"-mav_firstObject", ^{
	it(@"should return the first object", ^{
		NSArray *array = @[ @1, @2, @3 ];
		expect(array.mav_firstObject).to.equal(@1);
	});

	it(@"should return nil for an empty array", ^{
		NSArray *array = @[];
		expect(array.mav_firstObject).to.beNil();
	});
});

describe(@"-mav_arrayByRemovingObject:", ^{
	it(@"should return a new array without the object", ^{
		NSArray *array = @[ @1, @2, @3 ];
		NSArray *expected = @[ @2, @3 ];
		expect([array mav_arrayByRemovingObject:@1]).to.equal(expected);
	});

	it(@"should return a new array without all occurrences of the object", ^{
		NSArray *array = @[ @1, @2, @3, @1, @1 ];
		NSArray *expected = @[ @2, @3 ];
		expect([array mav_arrayByRemovingObject:@1]).to.equal(expected);
	});
	
	it(@"should return an equivalent array if it doesn't contain the object", ^{
		NSArray *array = @[ @1, @2, @3 ];
		expect([array mav_arrayByRemovingObject:@42]).to.equal(array);
	});
});

describe(@"-mav_arrayByRemovingFirstObject", ^{
	it(@"should return the array without the first object", ^{
		NSArray *array = @[ @1, @2, @3 ];
		NSArray *expected = @[ @2, @3 ];
		expect(array.mav_arrayByRemovingFirstObject).to.equal(expected);
	});

	it(@"should return the same array if it's empty", ^{
		NSArray *array = @[];
		expect(array.mav_arrayByRemovingFirstObject).to.equal(array);
	});
});

describe(@"-mav_arrayByRemovingLastObject", ^{
	it(@"should return the array without the last object", ^{
		NSArray *array = @[ @1, @2, @3 ];
		NSArray *expected = @[ @1, @2 ];
		expect(array.mav_arrayByRemovingLastObject).to.equal(expected);
	});

	it(@"should return the same array if it's empty", ^{
		NSArray *array = @[];
		expect(array.mav_arrayByRemovingLastObject).to.equal(array);
	});
});

SpecEnd
