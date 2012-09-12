//
//  MAVValueTransformer.h
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^MAVValueTransformerBlock)(id);

// The name for a value transformer that converts strings into URLs and back.
extern NSString * const MAVURLValueTransformerName;

//
// A value transformer supporting block-based transformation.
//
@interface MAVValueTransformer : NSValueTransformer

// Returns a transformer which transforms values using the given block. Reverse
// transformations will not be allowed.
+ (instancetype)transformerWithBlock:(MAVValueTransformerBlock)transformationBlock;

// Returns a transformer which transforms values using the given block, for
// forward or reverse transformations.
+ (instancetype)reversibleTransformerWithBlock:(MAVValueTransformerBlock)transformationBlock;

// Returns a transformer which transforms values using the given blocks.
+ (instancetype)reversibleTransformerWithForwardBlock:(MAVValueTransformerBlock)forwardBlock reverseBlock:(MAVValueTransformerBlock)reverseBlock;

@end
