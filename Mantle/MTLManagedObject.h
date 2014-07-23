//
//  MTLManagedObject.h
//  Mantle
//
//  Created by Robert Böhnke on 17/05/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "MTLModel.h"

@interface MTLManagedObject : NSManagedObject <MTLModel>

+ (NSEntityDescription *)entityDescription;

@end
