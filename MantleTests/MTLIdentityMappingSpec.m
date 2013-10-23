//
//  MTLIdentityMappingSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 10/23/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

#import "MTLIdentityMapping.h"

SpecBegin(MTLIdentityMapping)

it(@"should return a mapping", ^{
	NSDictionary *mapping = @{
		@"name": @"name",
		@"count": @"count",
		@"nestedName": @"nestedName",
		@"weakModel": @"weakModel"
	};

	expect(MTLIdentityMappingForClass(MTLTestModel.class)).to.equal(mapping);
});

SpecEnd
