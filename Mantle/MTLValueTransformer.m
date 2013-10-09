//
//  MTLValueTransformer.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

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

+ (instancetype)transformerUsingBlock:(MTLValueTransformationBlock)transformation {
	return [[self alloc] initWithForwardTransformation:transformation reverseTransformation:nil];
}

+ (instancetype)reversibleUsingBlock:(MTLValueTransformationBlock)transformation {
	return [self reversibleTransformerUsingForwardBlock:transformation reverseBlock:transformation];
}

+ (instancetype)reversibleTransformerUsingForwardBlock:(MTLValueTransformationBlock)forwardTransformation reverseBlock:(MTLValueTransformationBlock)reverseTransformation {
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
	NSError *error = nil;
	BOOL success = YES;

	return self.forwardBlock(value, &success, &error);
}

- (id)transformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError **)outerError {
	NSError *error = nil;
	BOOL success = YES;

	id transformedValue = self.forwardBlock(value, &success, &error);

	if (outerSuccess != NULL) *outerSuccess = success;
	if (outerError != NULL) *outerError = error;

	return transformedValue;
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
	NSError *error = nil;
	BOOL success = YES;

	return self.reverseBlock(value, &success, &error);
}

- (id)reverseTransformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError **)outerError {
	NSError *error = nil;
	BOOL success = YES;

	id transformedValue = self.reverseBlock(value, &success, &error);

	if (outerSuccess != NULL) *outerSuccess = success;
	if (outerError != NULL) *outerError = error;

	return transformedValue;
}

@end


@implementation MTLValueTransformer (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (instancetype)transformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [self transformerUsingBlock:^(id value, BOOL *success, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithBlock:(MTLValueTransformerBlock)transformationBlock {
	return [self reversibleUsingBlock:^(id value, BOOL *success, NSError **error) {
		return transformationBlock(value);
	}];
}

+ (instancetype)reversibleTransformerWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock {
	return [self
		reversibleTransformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return forwardBlock(value);
		}
		reverseBlock:^(id value, BOOL *success, NSError **error) {
			return reverseBlock(value);
		}];
}

#pragma clang diagnostic pop

@end
