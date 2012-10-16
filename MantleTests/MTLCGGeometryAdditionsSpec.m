//
//  MTLCGGeometryAdditionsSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 18.01f.12.
//  Copyright 2012 GitHub. All rights reserved.
//

/*

Portions copyright (c) 2012, Bitswift, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Neither the name of the Bitswift, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

SpecBegin(MTLCGGeometryAdditions)

describe(@"CGRectCenterPoint", ^{
	it(@"should return the center of a valid rectangle", ^{
		CGRect rect = CGRectMake(10, 20, 30, 40);
		expect(CGRectCenterPoint(rect)).to.equal(CGPointMake(25, 40));
	});

	it(@"should return the center of an empty rectangle", ^{
		CGRect rect = CGRectMake(10, 20, 0, 0);
		expect(CGRectCenterPoint(rect)).to.equal(CGPointMake(10, 20));
	});

	it(@"should return non-integral center points", ^{
		CGRect rect = CGRectMake(10, 20, 15, 7);
		expect(CGRectCenterPoint(rect)).to.equal(CGPointMake(17.5f, 23.5f));
	});
});

describe(@"CGRectDivideWithPadding", ^{
	CGRect rect = CGRectMake(50, 50, 100, 100);

	__block CGRect slice, remainder;
	before(^{
		slice = CGRectZero;
		remainder = CGRectZero;
	});

	it(@"divides with padding", ^{
		CGRect expectedSlice = CGRectMake(50, 50, 40, 100);
		CGRect expectedRemainder = CGRectMake(90 + 10, 50, 50, 100);

		CGRectDivideWithPadding(rect, &slice, &remainder, 40, 10, CGRectMinXEdge);

		expect(slice).to.equal(expectedSlice);
		expect(remainder).to.equal(expectedRemainder);
	});

	it(@"divides with a null slice", ^{
		CGRect expectedRemainder = CGRectMake(90 + 10, 50, 50, 100);

		CGRectDivideWithPadding(rect, NULL, &remainder, 40, 10, CGRectMinXEdge);
		expect(remainder).to.equal(expectedRemainder);
	});

	it(@"divides with a null remainder", ^{
		CGRect expectedSlice = CGRectMake(50, 50, 40, 100);
		CGRectDivideWithPadding(rect, &slice, NULL, 40, 10, CGRectMinXEdge);
		expect(slice).to.equal(expectedSlice);
	});

	it(@"divides with no space for remainder", ^{
		CGRect expectedSlice = CGRectMake(50, 50, 95, 100);
		CGRectDivideWithPadding(rect, &slice, &remainder, 95, 10, CGRectMinXEdge);
		expect(slice).to.equal(expectedSlice);
		expect(CGRectIsEmpty(remainder)).to.beTruthy();
	});
});

describe(@"CGRectRemainder", ^{
	it(@"should return the rectangle's remainder", ^{
		CGRect rect = CGRectMake(100, 100, 100, 100);

		CGRect result = CGRectRemainder(rect, 25, CGRectMaxXEdge);
		CGRect expectedResult = CGRectMake(100, 100, 75, 100);

		expect(result).to.equal(expectedResult);
	});
});

describe(@"CGRectGrow", ^{
	it(@"should return a larger rectangle", ^{
		CGRect rect = CGRectMake(100, 100, 100, 100);

		CGRect result = CGRectGrow(rect, 25, CGRectMinXEdge);
		CGRect expectedResult = CGRectMake(75, 100, 125, 100);
		expect(result).to.equal(expectedResult);
	});
});

describe(@"CGRectFloor", ^{
	it(@"leaves integers untouched", ^{
		CGRect rect = CGRectMake(-10, 20, -30, 40);
		CGRect result = CGRectFloor(rect);
		expect(result).to.equal(rect);
	});

	it(@"rounds down, except in Y.", ^{
		CGRect rect = CGRectMake(10.1f, 1.1f, -3.4f, -4.7f);

		CGRect result = CGRectFloor(rect);
		CGRect expectedResult = CGRectMake(10, 2, -4, -5);
		expect(result).to.equal(expectedResult);
	});

	it(@"leaves CGRectNull untouched", ^{
		CGRect rect = CGRectNull;
		CGRect result = CGRectFloor(rect);
		expect(result).to.equal(rect);
	});

	it(@"leaves CGRectInfinite untouched", ^{
		CGRect rect = CGRectInfinite;
		CGRect result = CGRectFloor(rect);
		expect(result).to.equal(rect);
	});
});

describe(@"inverted rectangles", ^{
	it(@"should create an inverted rectangle within a containing rectangle", ^{
		CGRect containingRect = CGRectMake(0, 0, 100, 100);

		// Bottom Left
		CGRect expectedResult = CGRectMake(0, CGRectGetHeight(containingRect) - 20 - 50, 50, 50);

		CGRect result = CGRectMakeInverted(containingRect, 0, 20, 50, 50);
		expect(result).to.equal(expectedResult);
	});

	it(@"should invert a rectangle within a containing rectangle", ^{
		CGRect rect = CGRectMake(0, 20, 50, 50);
		CGRect containingRect = CGRectMake(0, 0, 100, 100);

		// Bottom Left
		CGRect expectedResult = CGRectMake(0, CGRectGetHeight(containingRect) - 20 - 50, 50, 50);

		CGRect result = CGRectInvert(containingRect, rect);
		expect(result).to.equal(expectedResult);
	});
});

describe(@"CGRectWithSize", ^{
	it(@"should return a rectangle with a valid size", ^{
		CGRect rect = CGRectWithSize(CGSizeMake(20, 40));
		expect(rect).to.equal(CGRectMake(0, 0, 20, 40));
	});

	it(@"should return a rectangle with zero size", ^{
		CGRect rect = CGRectWithSize(CGSizeZero);
		expect(rect).to.equal(CGRectZero);
	});
});

describe(@"CGPointFloor", ^{
	it(@"rounds components up and left", ^{
		CGPoint point = CGPointMake(0.5f, 0.49f);
		CGPoint point2 = CGPointMake(-0.5f, -0.49f);
		expect(CGPointEqualToPoint(CGPointFloor(point), CGPointMake(0, 1))).to.beTruthy();
		expect(CGPointEqualToPoint(CGPointFloor(point2), CGPointMake(-1, 0))).to.beTruthy();
	});
});

describe(@"equality with accuracy", ^{
	CGRect rect = CGRectMake(0.5f, 1.5f, 15, 20);
	CGFloat epsilon = 0.6f;

	CGRect closeRect = CGRectMake(1, 1, 15.5f, 19.75f);
	CGRect farRect = CGRectMake(1.5f, 11.5f, 20, 20);

	it(@"compares two points that are close enough", ^{
		expect(CGPointEqualToPointWithAccuracy(rect.origin, closeRect.origin, epsilon)).to.beTruthy();
	});

	it(@"compares two points that are too far from each other", ^{
		expect(CGPointEqualToPointWithAccuracy(rect.origin, farRect.origin, epsilon)).to.beFalsy();
	});

	it(@"compares two rectangles that are close enough", ^{
		expect(CGRectEqualToRectWithAccuracy(rect, closeRect, epsilon)).to.beTruthy();
	});

	it(@"compares two rectangles that are too far from each other", ^{
		expect(CGRectEqualToRectWithAccuracy(rect, farRect, epsilon)).to.beFalsy();
	});

	it(@"compares two sizes that are close enough", ^{
		expect(CGSizeEqualToSizeWithAccuracy(rect.size, closeRect.size, epsilon)).to.beTruthy();
	});

	it(@"compares two sizes that are too far from each other", ^{
		expect(CGSizeEqualToSizeWithAccuracy(rect.size, farRect.size, epsilon)).to.beFalsy();
	});
});

describe(@"CGSizeScale", ^{
	it(@"should scale each component", ^{
		CGSize original = CGSizeMake(-5, 3.4f);
		CGFloat scale = -3.5f;

		CGSize scaledSize = CGSizeScale(original, scale);
		CGSize expected = CGSizeMake(17.5f, -11.9f);

		expect(scaledSize.width).to.beCloseTo(expected.width);
		expect(scaledSize.height).to.beCloseTo(expected.height);
	});
});

describe(@"CGPointAdd", ^{
	it(@"adds two points together, element-wise", ^{
		CGPoint point1 = CGPointMake(-1, 5);
		CGPoint point2 = CGPointMake(10, 12);
		CGPoint sum = CGPointAdd(point1, point2);
		expect(sum).to.equal(CGPointMake(9, 17));
	});
});

describe(@"CGPointSubtract", ^{
	it(@"adds two points together, element-wise", ^{
		CGPoint point1 = CGPointMake(-1, 5);
		CGPoint point2 = CGPointMake(10, 12);
		CGPoint diff = CGPointSubtract(point1, point2);
		expect(diff).to.equal(CGPointMake(-11, -7));
	});
});

SpecEnd
