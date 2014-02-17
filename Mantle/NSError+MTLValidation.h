//
//  NSError+MTLValidation.h
//  Mantle
//
//  Created by Sasha Zats on 2/13/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (MTLValidation)

+ (instancetype)mtl_umbrellaErrorWithErrors:(NSArray *)errors;

+ (instancetype)mtl_validationErrorForProperty:(NSString *)property
                                  expectedType:(NSString *)expectedType
                                  receivedType:(NSString *)receivedType;

@end
