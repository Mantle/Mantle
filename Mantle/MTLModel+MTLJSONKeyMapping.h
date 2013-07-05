//
//  MTLModel+MTLJSONKeyMapping.h
//  Mantle
//
//  Created by Jonas Budelmann on 6/07/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

@interface MTLModel (MTLJSONKeyMapping)

+ (void)setJSONKeyPathsByPropertyKey:(NSDictionary *)JSONKeyPathsByPropertyKey forModel:(MTLModel *)model;

+ (NSDictionary *)JSONKeyPathsByPropertyKeyForModel:(MTLModel *)model;

@end
