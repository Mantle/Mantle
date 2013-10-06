//
//  MTLValueTransformer.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTLTransformerErrorHandling.h"

typedef id (^MTLValueTransformationBlock)(id, NSError **);

//
// A value transformer supporting block-based transformation.
//
@interface MTLValueTransformer : NSValueTransformer <MTLTransformerErrorHandling>

// Returns a transformer which transforms values using the given block. Reverse
// transformations will not be allowed.
+ (instancetype)transformerWithTransformation:(MTLValueTransformationBlock)transformation;

// Returns a transformer which transforms values using the given block, for
// forward or reverse transformations.
+ (instancetype)reversibleTransformerWithTransformation:(MTLValueTransformationBlock)transformation;

// Returns a transformer which transforms values using the given blocks.
+ (instancetype)reversibleTransformerWithForwardTransformation:(MTLValueTransformationBlock)forwardTransformation reverseTransformation:(MTLValueTransformationBlock)reverseTransformation;

@end

typedef id (^MTLValueTransformerBlock)(id);

@interface MTLValueTransformer (Deprecated)

+ (instancetype)transformerWithBlock:(MTLValueTransformerBlock)transformationBlock __attribute__((deprecated));

+ (instancetype)reversibleTransformerWithBlock:(MTLValueTransformerBlock)transformationBlock __attribute__((deprecated));

+ (instancetype)reversibleTransformerWithForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock __attribute__((deprecated));

@end
