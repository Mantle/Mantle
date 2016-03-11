//
//  MTLRuntimeRoutines.h
//  Mantle
//
//  Created by Anton Bukov on 3/11/16.
//  Copyright (c) 2016 ML-Works. All rights reserved.
//

#import <Foundation/Foundation.h>

void MTLRuntimeEnumerateClasses(void (^block)(Class class));
void MTLRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class));
