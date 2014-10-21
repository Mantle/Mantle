//
//  MTLValueTransformerInversionAdditionsSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

@interface TestTransformer : NSValueTransformer
@end

@implementation TestTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return NSString.class;
}

- (id)transformedValue:(id)value {
	return @"forward";
}

- (id)reverseTransformedValue:(id)value {
	return @"reverse";
}

@end

QuickSpecBegin(MTLValueTransformerInversionAdditions)

__block TestTransformer *transformer;

beforeEach(^{
	transformer = [[TestTransformer alloc] init];
	expect(transformer).notTo(beNil());
});

it(@"should invert a transformer", ^{
	NSValueTransformer *inverted = transformer.mtl_invertedTransformer;
	expect(inverted).notTo(beNil());

	expect([inverted transformedValue:nil]).to(equal(@"reverse"));
	expect([inverted reverseTransformedValue:nil]).to(equal(@"forward"));
});

it(@"should invert an inverted transformer", ^{
	NSValueTransformer *inverted = transformer.mtl_invertedTransformer.mtl_invertedTransformer;
	expect(inverted).notTo(beNil());

	expect([inverted transformedValue:nil]).to(equal(@"forward"));
	expect([inverted reverseTransformedValue:nil]).to(equal(@"reverse"));
});

QuickSpecEnd
