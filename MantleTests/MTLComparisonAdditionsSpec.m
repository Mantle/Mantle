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
    it(@"should determine equality even with nil values", ^{
        id obj1 = @"Test1";
        id obj2 = @"Test2";

        expect(MTLEqualObjects(nil, nil)).to.beTruthy();
        expect(MTLEqualObjects(nil, obj1)).to.beFalsy();
        expect(MTLEqualObjects(obj1, nil)).to.beFalsy();
        expect(MTLEqualObjects(obj1, obj1)).to.beTruthy();
        expect(MTLEqualObjects(obj1, obj2)).to.beFalsy();
    });
});

SpecEnd
