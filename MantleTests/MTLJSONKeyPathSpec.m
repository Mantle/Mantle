//
//  MTLJSONAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/NSDictionary+MTLJSONKeyPath.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

QuickSpecBegin(MTLJSONKeyPathSpec)

it(@"should handle key paths with dot literals", ^{
	NSDictionary *dictionary = @{
		@"test.soup": @0,
		@"test": @{@"soup": @1},
	};

	NSError *error = nil;
	BOOL success = NO;
	NSNumber *value = [dictionary mtl_valueForJSONKeyPath:@"test\\.soup" success:&success error:&error];
	
	expect(error).to(beNil());
	expect(success).to(beTrue());
	expect(value).to(equal(@0));

	error = nil;
	success = NO;
	NSNumber *deepValue = [dictionary mtl_valueForJSONKeyPath:@"test.soup" success:&success error:&error];
	
	expect(error).to(beNil());
	expect(success).to(beTrue());
	expect(deepValue).to(equal(@1));
});

QuickSpecEnd
