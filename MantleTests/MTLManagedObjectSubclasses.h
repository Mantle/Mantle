//
//  MTLManagedObjectSubclasses.h
//  Mantle
//
//  Created by Robert Böhnke on 17/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface MTLManagedObjectParent : MTLManagedObject

@property (readwrite, nonatomic, strong) NSDate *date;
@property (readwrite, nonatomic, strong) NSNumber *number;
@property (readwrite, nonatomic, copy) NSString *string;
@property (readwrite, nonatomic, copy) NSString *url;

+ (NSManagedObjectModel *)managedObjectModel;

@end
