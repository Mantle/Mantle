//
//  MTLModel+MTLJSONKeyMapping.m
//  Mantle
//
//  Created by Jonas Budelmann on 6/07/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel+MTLJSONKeyMapping.h"
#import <objc/runtime.h>

// Used to cache the propertyKey to JSONKeyPath if there are multiple possibilities
static void *MTLModelJSONKeyPathsForInstanceKey = &MTLModelJSONKeyPathsForInstanceKey;

@implementation MTLModel (MTLJSONKeyMapping)

+ (void)setJSONKeyPathsByPropertyKey:(NSDictionary *)JSONKeyPathsByPropertyKey forModel:(MTLModel *)model {
	objc_setAssociatedObject(model, MTLModelJSONKeyPathsForInstanceKey, JSONKeyPathsByPropertyKey, OBJC_ASSOCIATION_COPY);
}

+ (NSDictionary *)JSONKeyPathsByPropertyKeyForModel:(MTLModel *)model {
	return objc_getAssociatedObject(model, MTLModelJSONKeyPathsForInstanceKey);
}

@end
