//
//  MTLRuntimeRoutines.m
//  Mantle
//
//  Created by Anton Bukov on 3/11/16.
//  Copyright (c) 2016 ML-Works. All rights reserved.
//

#import <objc/runtime.h>
#import "MTLRuntimeRoutines.h"

void MTLRuntimeEnumerateClasses(void (^block)(Class class)) {
	MTLRuntimeEnumerateClassSubclasses([NSObject class], block);
}

void MTLRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class)) {
	int classesCount = objc_getClassList(NULL, 0);
	Class *classes = (Class *)malloc(classesCount * sizeof(Class));
	objc_getClassList(classes, classesCount);
	
	for (int i = 0; i < classesCount; i++) {
		Class class = classes[i];
		
		// Filter only NSObject subclasses
		Class superclass = class;
		while (superclass && superclass != parentclass) {
			superclass = class_getSuperclass(superclass);
		}
		if (!superclass) {
			continue;
		}
		
		block(class);
	}
	
	free(classes);
}
