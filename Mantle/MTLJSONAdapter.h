//
//  MTLJSONAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTLJSONSerializing
@optional

+ (NSDictionary *)JSONKeyPathsByPropertyKey;

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;
+ (NSDictionary *)migrateJSONRepresentation:(NSDictionary *)externalRepresentation fromVersion:(NSUInteger)fromVersion;

@end

@interface MTLJSONAdapter : NSObject

+ (NSDictionary *)JSONFromModel:(MTLModel<MTLJSONSerializing> *)model;
+ (id)modelOfClass:(Class)modelClass fromJSON:(NSDictionary *)dict;

@end
