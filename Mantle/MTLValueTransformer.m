//
//  MTLValueTransformer.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLErrorHandling.h"

#import "MTLValueTransformer.h"

//
// Any MTLValueTransformer supporting reverse transformation. Necessary because
// +allowsReverseTransformation is a class method.
//
@interface MTLReversibleValueTransformer : MTLValueTransformer
@end

@interface MTLValueTransformer ()

@property (nonatomic, copy, readonly) MTLValueTransformationBlock forwardBlock;
@property (nonatomic, copy, readonly) MTLValueTransformationBlock reverseBlock;

@end

@implementation MTLValueTransformer

#pragma mark Lifecycle

+ (instancetype)transformerWithTransformation:(MTLValueTransformationBlock)transformation {
	return [[self alloc] initWithForwardTransformation:transformation reverseTransformation:nil];
}

+ (instancetype)reversibleTransformerWithTransformation:(MTLValueTransformationBlock)transformation {
	return [self reversibleTransformerWithForwardTransformation:transformation reverseTransformation:transformation];
}

+ (instancetype)reversibleTransformerWithForwardTransformation:(MTLValueTransformationBlock)forwardTransformation reverseTransformation:(MTLValueTransformationBlock)reverseTransformation {
	return [[MTLReversibleValueTransformer alloc] initWithForwardTransformation:forwardTransformation reverseTransformation:reverseTransformation];
}

- (id)initWithForwardTransformation:(MTLValueTransformationBlock)forwardTransformation reverseTransformation:(MTLValueTransformationBlock)reverseTransformation {
	NSParameterAssert(forwardTransformation != nil);

	self = [super init];
	if (self == nil) return nil;

	_forwardBlock = [forwardTransformation copy];
	_reverseBlock = [reverseTransformation copy];

	return self;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return NO;
}

+ (Class)transformedValueClass {
	return NSObject.class;
}

- (id)transformedValue:(id)value {
	return self.forwardBlock(value, NULL);
}

- (id)mtl_transformedValue:(id)value error:(NSError **)error {
	return self.forwardBlock(value, error);
}

@end

@implementation MTLReversibleValueTransformer

#pragma mark Lifecycle

- (id)initWithForwardTransformation:(MTLValueTransformationBlock)forwardTransformation reverseTransformation:(MTLValueTransformationBlock)reverseTransformation {
	NSParameterAssert(reverseTransformation != nil);
	return [super initWithForwardTransformation:forwardTransformation reverseTransformation:reverseTransformation];
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)reverseTransformedValue:(id)value {
	return self.reverseBlock(value, NULL);
}

- (id)mtl_reverseTransformedValue:(id)value error:(NSError **)error {
	return self.reverseBlock(value, error);
}

@end


@implementation MTLValueTransformer (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (instancetype)transformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [self transformerWithTransformation:^(id value, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [self reversibleTransformerWithTransformation:^(id value, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock {
	return [self
		reversibleTransformerWithForwardTransformation:^(id value, NSError **error) {
			return forwardBlock(value);
		}
		reverseTransformation:^(id value, NSError **error) {
			return reverseBlock(value);
		}];
}

#pragma clang diagnostic pop

@end