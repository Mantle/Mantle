//
//  MTLKeyedArchiveAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTLKeyedArchiving
@optional

+ (MTLModelEncodingBehavior)encodingBehaviorsByPropertyKey;

@end

@interface MTLKeyedArchiveAdapter : NSObject <NSCoding>

- (id)initWithModel:(MTLModel<MTLKeyedArchiving> *)model;

// The decoded model when initialized from a coder.
@property (nonatomic, strong, readonly) id model;

@end
