//
//  MTLError.h
//  Mantle
//
//  Created by Sasha Zats on 2/13/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

// The domain for errors originating from MTLModel.
extern NSString * const MTLModelErrorDomain;

// Associated with the NSException that was caught.
extern NSString * const MTLModelThrownExceptionErrorKey;

extern NSString * const MTLDetailedErrorsKey;

enum {
	MTLModelErrorExceptionThrown    = 1,    // generic exceptin caught during parsing
	MTLModelValidationError         = 2     // generic validation error
};
