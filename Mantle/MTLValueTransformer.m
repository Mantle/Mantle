//
//  MTLValueTransformer.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLValueTransformer.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";

//
// Any MTLValueTransformer supporting reverse transformation. Necessary because
// +allowsReverseTransformation is a class method.
//
@interface MTLReversibleValueTransformer : MTLValueTransformer
@end

@interface MTLValueTransformer ()

@property (nonatomic, copy, readonly) MTLValueTransformerBlock forwardBlock;
@property (nonatomic, copy, readonly) MTLValueTransformerBlock reverseBlock;

@end

@implementation MTLValueTransformer

#pragma mark Lifecycle

+ (instancetype)transformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [[self alloc] initWithForwardBlock:transformationBlock reverseBlock:nil];
}

+ (instancetype)reversibleTransformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [self reversibleTransformerWithForwardBlock:transformationBlock reverseBlock:transformationBlock];
}

+ (instancetype)reversibleTransformerWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock {
	return [[MTLReversibleValueTransformer alloc] initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

- (id)initWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock {
	NSParameterAssert(forwardBlock != nil);

	self = [super init];
	if (self == nil) return nil;

	_forwardBlock = [forwardBlock copy];
	_reverseBlock = [reverseBlock copy];

	return self;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return NO;
}

+ (Class)transformedValueClass {
	return [NSObject class];
}

- (id)transformedValue:(id)value {
	return self.forwardBlock(value);
}

@end

@implementation MTLReversibleValueTransformer

#pragma mark Class Initialization

// Set up common transformers in this subclass so that we can be sure that both
// classes have been properly loaded.
+ (void)load {
	MTLValueTransformer *URLValueTransformer = [self
		reversibleTransformerWithForwardBlock:^ id (NSString *str) {
			if (![str isKindOfClass:[NSString class]]) return nil;
			return [NSURL URLWithString:str];
		}
		reverseBlock:^ id (NSURL *URL) {
			if (![URL isKindOfClass:[NSURL class]]) return nil;
			return URL.absoluteString;
		}];
	
	[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];
}

#pragma mark Lifecycle

- (id)initWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock {
	NSParameterAssert(reverseBlock != nil);
	return [super initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)reverseTransformedValue:(id)value {
	return self.reverseBlock(value);
}

@end
