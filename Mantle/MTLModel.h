//
//  MTLModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTLBaseModel.h"

// An abstract base class for model objects, using reflection to provide
// sensible default behaviors.
//
// The default implementations of <NSCopying>, -hash, and -isEqual: make use of
// the +propertyKeys method.
@interface MTLModel : NSObject <MTLModelProtocol, NSCopying>

@end

@interface MTLModel (Unavailable)

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue __attribute__((deprecated("Replaced by +modelWithDictionary:error:")));
- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue __attribute__((deprecated("Replaced by -initWithDictionary:error:")));

+ (instancetype)modelWithExternalRepresentation:(NSDictionary *)externalRepresentation __attribute__((deprecated("Replaced by -[MTLJSONAdapter initWithJSONDictionary:modelClass:]")));
- (instancetype)initWithExternalRepresentation:(NSDictionary *)externalRepresentation __attribute__((deprecated("Replaced by -[MTLJSONAdapter initWithJSONDictionary:modelClass:]")));

@property (nonatomic, copy, readonly) NSDictionary *externalRepresentation __attribute__((deprecated("Replaced by MTLJSONAdapter.JSONDictionary")));

+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey __attribute__((deprecated("Replaced by +JSONKeyPathsByPropertyKey in <MTLJSONSerializing>")));
+ (NSValueTransformer *)transformerForKey:(NSString *)key __attribute__((deprecated("Replaced by +JSONTransformerForKey: in <MTLJSONSerializing>")));

+ (NSDictionary *)migrateExternalRepresentation:(NSDictionary *)externalRepresentation fromVersion:(NSUInteger)fromVersion __attribute__((deprecated("Replaced by -decodeValueForKey:withCoder:modelVersion:")));

@end
